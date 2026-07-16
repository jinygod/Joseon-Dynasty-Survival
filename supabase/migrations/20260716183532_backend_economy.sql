create extension if not exists pgcrypto with schema extensions;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_permanent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.player_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  schema_version integer not null check (schema_version > 0),
  revision bigint not null default 1 check (revision > 0),
  progress jsonb not null check (jsonb_typeof(progress) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  royal_jade bigint not null default 0 check (royal_jade >= 0),
  royal_jade_debt bigint not null default 0 check (royal_jade_debt >= 0),
  version bigint not null default 0 check (version >= 0),
  updated_at timestamptz not null default now()
);

create table public.wallet_ledger (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  subject_hash text not null,
  currency_code text not null check (currency_code = 'royal_jade'),
  delta bigint not null check (delta <> 0),
  balance_after bigint not null check (balance_after >= 0),
  reason text not null,
  reference_type text not null,
  reference_id text not null,
  idempotency_key text not null unique,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now()
);
create index wallet_ledger_user_id_created_at_idx on public.wallet_ledger (user_id, created_at desc);

create table private.product_catalog (
  product_id text primary key,
  currency_code text not null check (currency_code = 'royal_jade'),
  grant_amount bigint not null check (grant_amount > 0),
  active boolean not null default true,
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into private.product_catalog (product_id, currency_code, grant_amount)
values ('royal_jade_small', 'royal_jade', 100),
       ('royal_jade_medium', 'royal_jade', 550),
       ('royal_jade_large', 'royal_jade', 1200);

create table private.google_play_purchases (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  subject_hash text not null,
  product_id text not null,
  purchase_token text not null unique,
  order_id text,
  purchase_state text not null,
  acknowledgement_state text,
  consumption_state text,
  quantity integer not null default 1 check (quantity = 1),
  granted_amount bigint not null default 0 check (granted_amount >= 0),
  raw_verification jsonb,
  verified_at timestamptz,
  consumed_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index google_play_purchases_user_id_idx on private.google_play_purchases (user_id);

create table private.premium_catalog (
  sku text primary key,
  royal_jade_price bigint not null check (royal_jade_price > 0),
  entitlement_key text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.player_entitlements (
  user_id uuid not null references auth.users(id) on delete cascade,
  entitlement_key text not null,
  acquired_at timestamptz not null default now(),
  ledger_id uuid not null references public.wallet_ledger(id),
  primary key (user_id, entitlement_key)
);

create or replace function private.handle_auth_user_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, is_permanent)
  values (new.id, not coalesce(new.is_anonymous, true))
  on conflict (user_id) do update set
    is_permanent = public.profiles.is_permanent or excluded.is_permanent,
    updated_at = now();
  insert into public.wallets (user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger auth_user_profile_wallet
after insert or update of is_anonymous on auth.users
for each row execute function private.handle_auth_user_change();

alter table public.profiles enable row level security;
alter table public.player_progress enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_ledger enable row level security;
alter table public.player_entitlements enable row level security;
alter table private.product_catalog enable row level security;
alter table private.google_play_purchases enable row level security;
alter table private.premium_catalog enable row level security;

create policy profile_read_own on public.profiles for select to authenticated
using ((select auth.uid()) = user_id);
create policy player_progress_read_own on public.player_progress for select to authenticated
using ((select auth.uid()) = user_id);
create policy wallet_read_own on public.wallets for select to authenticated
using ((select auth.uid()) = user_id);
create policy wallet_ledger_read_own on public.wallet_ledger for select to authenticated
using ((select auth.uid()) = user_id);
create policy player_entitlements_read_own on public.player_entitlements for select to authenticated
using ((select auth.uid()) = user_id);

revoke all on public.profiles, public.player_progress, public.wallets,
  public.wallet_ledger, public.player_entitlements from anon, authenticated;
grant select on public.profiles, public.player_progress, public.wallets,
  public.wallet_ledger, public.player_entitlements to authenticated;
revoke all on all tables in schema private from public, anon, authenticated;

create or replace function private.subject_hash(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select encode(
    extensions.hmac(
      convert_to(p_user_id::text, 'utf8'),
      convert_to(current_setting('app.settings.jwt_secret'), 'utf8'),
      'sha256'
    ),
    'hex'
  )
$$;

create or replace function private.assert_permanent_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user_id is null or not exists (
    select 1 from public.profiles p
    join auth.users u on u.id = p.user_id
    where p.user_id = p_user_id
      and p.is_permanent
      and not coalesce(u.is_anonymous, false)
  ) then
    raise exception using errcode = 'P0001', message = 'permanent_user_required';
  end if;
end;
$$;

create or replace function private.apply_wallet_entry(
  p_user_id uuid,
  p_delta bigint,
  p_reason text,
  p_reference_type text,
  p_reference_id text,
  p_idempotency_key text,
  p_metadata jsonb default '{}'::jsonb
)
returns table (ledger_id uuid, balance bigint, debt bigint, wallet_version bigint)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_wallet public.wallets%rowtype;
  v_ledger public.wallet_ledger%rowtype;
  v_credit bigint;
  v_shortfall bigint;
begin
  perform private.assert_permanent_user(p_user_id);
  if p_delta = 0 or p_reason is null or p_reference_type is null or p_reference_id is null
     or p_idempotency_key is null or jsonb_typeof(coalesce(p_metadata, '{}'::jsonb)) <> 'object' then
    raise exception using errcode = '22023', message = 'invalid_wallet_entry';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_idempotency_key, 0));
  insert into public.wallets (user_id) values (p_user_id) on conflict (user_id) do nothing;
  select * into v_wallet from public.wallets where user_id = p_user_id for update;
  select * into v_ledger from public.wallet_ledger where idempotency_key = p_idempotency_key;
  if found then
    if v_ledger.user_id is distinct from p_user_id then
      raise exception using errcode = '23505', message = 'idempotency_key_conflict';
    end if;
    return query select v_ledger.id, v_ledger.balance_after, v_wallet.royal_jade_debt, v_wallet.version;
    return;
  end if;

  if p_delta > 0 then
    v_credit := greatest(p_delta - v_wallet.royal_jade_debt, 0);
    v_wallet.royal_jade_debt := greatest(v_wallet.royal_jade_debt - p_delta, 0);
    v_wallet.royal_jade := v_wallet.royal_jade + v_credit;
  else
    v_shortfall := greatest((-p_delta) - v_wallet.royal_jade, 0);
    v_wallet.royal_jade := greatest(v_wallet.royal_jade + p_delta, 0);
    v_wallet.royal_jade_debt := v_wallet.royal_jade_debt + v_shortfall;
  end if;
  v_wallet.version := v_wallet.version + 1;

  update public.wallets set
    royal_jade = v_wallet.royal_jade,
    royal_jade_debt = v_wallet.royal_jade_debt,
    version = v_wallet.version,
    updated_at = now()
  where user_id = p_user_id;

  insert into public.wallet_ledger
    (user_id, subject_hash, currency_code, delta, balance_after, reason,
     reference_type, reference_id, idempotency_key, metadata)
  values
    (p_user_id, private.subject_hash(p_user_id), 'royal_jade', p_delta,
     v_wallet.royal_jade, p_reason, p_reference_type, p_reference_id,
     p_idempotency_key, coalesce(p_metadata, '{}'::jsonb))
  returning * into v_ledger;
  return query select v_ledger.id, v_wallet.royal_jade, v_wallet.royal_jade_debt, v_wallet.version;
end;
$$;

create or replace function private.record_google_play_purchase(
  p_user_id uuid,
  p_product_id text,
  p_purchase_token text,
  p_order_id text,
  p_purchase_state text,
  p_raw_verification jsonb
)
returns table (purchase_id uuid, balance bigint, debt bigint, duplicate boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_product private.product_catalog%rowtype;
  v_purchase private.google_play_purchases%rowtype;
  v_wallet record;
begin
  perform private.assert_permanent_user(p_user_id);
  if p_purchase_state <> 'PURCHASED' then
    raise exception using errcode = 'P0001', message = 'purchase_not_completed';
  end if;
  select * into v_product from private.product_catalog where product_id = p_product_id and active;
  if not found then
    raise exception using errcode = 'P0001', message = 'unknown_product';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_purchase_token, 0));
  select * into v_purchase from private.google_play_purchases where purchase_token = p_purchase_token for update;
  if found then
    if v_purchase.user_id is distinct from p_user_id or v_purchase.product_id <> p_product_id then
      raise exception using errcode = 'P0001', message = 'purchase_token_owner_mismatch';
    end if;
    select w.royal_jade, w.royal_jade_debt into v_wallet from public.wallets w where w.user_id = p_user_id;
    return query select v_purchase.id, v_wallet.royal_jade, v_wallet.royal_jade_debt, true;
    return;
  end if;

  insert into private.google_play_purchases
    (user_id, subject_hash, product_id, purchase_token, order_id, purchase_state,
     granted_amount, raw_verification, verified_at)
  values
    (p_user_id, private.subject_hash(p_user_id), p_product_id, p_purchase_token,
     p_order_id, p_purchase_state, v_product.grant_amount, p_raw_verification, now())
  returning * into v_purchase;
  select * into v_wallet from private.apply_wallet_entry(
    p_user_id, v_product.grant_amount, 'google_play_purchase', 'google_play_purchase',
    p_purchase_token, 'google-play:' || p_purchase_token,
    jsonb_build_object('product_id', p_product_id, 'purchase_id', v_purchase.id)
  );
  return query select v_purchase.id, v_wallet.balance, v_wallet.debt, false;
end;
$$;

create or replace function private.spend_for_entitlement(p_user_id uuid, p_sku text)
returns table (entitlement_key text, ledger_id uuid, balance bigint, duplicate boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item private.premium_catalog%rowtype;
  v_existing public.player_entitlements%rowtype;
  v_entry record;
begin
  perform private.assert_permanent_user(p_user_id);
  select * into v_item from private.premium_catalog where sku = p_sku;
  if not found then raise exception using errcode = 'P0001', message = 'unknown_sku'; end if;
  if not v_item.active then raise exception using errcode = 'P0001', message = 'inactive_sku'; end if;

  select pe.* into v_existing from public.player_entitlements pe
  where pe.user_id = p_user_id and pe.entitlement_key = v_item.entitlement_key;
  if found then
    return query select v_existing.entitlement_key, v_existing.ledger_id,
      (select w.royal_jade from public.wallets w where w.user_id = p_user_id), true;
    return;
  end if;
  perform 1 from public.wallets w where w.user_id = p_user_id for update;
  select pe.* into v_existing from public.player_entitlements pe
  where pe.user_id = p_user_id and pe.entitlement_key = v_item.entitlement_key;
  if found then
    return query select v_existing.entitlement_key, v_existing.ledger_id,
      (select w.royal_jade from public.wallets w where w.user_id = p_user_id), true;
    return;
  end if;
  if not exists (select 1 from public.wallets w where w.user_id = p_user_id and w.royal_jade >= v_item.royal_jade_price and w.royal_jade_debt = 0) then
    raise exception using errcode = 'P0001', message = 'insufficient_funds';
  end if;
  select * into v_entry from private.apply_wallet_entry(
    p_user_id, -v_item.royal_jade_price, 'premium_spend', 'premium_sku', p_sku,
    'entitlement:' || p_user_id::text || ':' || v_item.entitlement_key,
    jsonb_build_object('sku', p_sku, 'entitlement_key', v_item.entitlement_key)
  );
  insert into public.player_entitlements (user_id, entitlement_key, ledger_id)
  values (p_user_id, v_item.entitlement_key, v_entry.ledger_id)
  returning player_entitlements.* into v_existing;
  return query select v_existing.entitlement_key, v_existing.ledger_id, v_entry.balance, false;
end;
$$;

create or replace function private.sync_progress(
  p_user_id uuid,
  p_schema_version integer,
  p_progress jsonb,
  p_expected_revision bigint
)
returns table (schema_version integer, revision bigint, progress jsonb, applied boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare v_current public.player_progress%rowtype;
begin
  perform private.assert_permanent_user(p_user_id);
  if p_schema_version <= 0 or jsonb_typeof(p_progress) <> 'object'
     or p_progress ? 'royal_jade' or pg_column_size(p_progress) > 65536 then
    raise exception using errcode = '22023', message = 'invalid_progress';
  end if;
  select * into v_current from public.player_progress where user_id = p_user_id for update;
  if not found then
    if p_expected_revision <> 0 then
      return;
    end if;
    insert into public.player_progress (user_id, schema_version, revision, progress)
    values (p_user_id, p_schema_version, 1, p_progress) returning * into v_current;
    return query select v_current.schema_version, v_current.revision, v_current.progress, true;
  elsif v_current.revision <> p_expected_revision then
    return query select v_current.schema_version, v_current.revision, v_current.progress, false;
  else
    update public.player_progress set schema_version = p_schema_version,
      revision = v_current.revision + 1, progress = p_progress, updated_at = now()
    where user_id = p_user_id returning * into v_current;
    return query select v_current.schema_version, v_current.revision, v_current.progress, true;
  end if;
end;
$$;

revoke execute on all functions in schema private from public, anon, authenticated;
grant usage on schema private to service_role;
grant select on public.profiles, public.player_progress, public.wallets,
  public.wallet_ledger, public.player_entitlements to service_role;
grant select on private.product_catalog, private.google_play_purchases,
  private.premium_catalog to service_role;
grant execute on function private.apply_wallet_entry(uuid,bigint,text,text,text,text,jsonb),
  private.record_google_play_purchase(uuid,text,text,text,text,jsonb),
  private.spend_for_entitlement(uuid,text),
  private.sync_progress(uuid,integer,jsonb,bigint) to service_role;
