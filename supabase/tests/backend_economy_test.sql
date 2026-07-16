begin;
create extension if not exists pgtap with schema extensions;
select plan(34);

select has_schema('private');
select ok(to_regclass('public.profiles') is not null, 'profiles exists');
select ok(to_regclass('public.player_progress') is not null, 'player_progress exists');
select ok(to_regclass('public.wallets') is not null, 'wallets exists');
select ok(to_regclass('public.wallet_ledger') is not null, 'wallet_ledger exists');
select ok(to_regclass('private.google_play_purchases') is not null, 'google_play_purchases exists');
select ok(to_regclass('private.product_catalog') is not null, 'product_catalog exists');
select ok(to_regclass('private.premium_catalog') is not null, 'premium_catalog exists');
select ok(to_regclass('public.player_entitlements') is not null, 'player_entitlements exists');

select policies_are('public', 'wallets', array['wallet_read_own']);
select policies_are('public', 'wallet_ledger', array['wallet_ledger_read_own']);
select policies_are('public', 'player_entitlements', array['player_entitlements_read_own']);

insert into auth.users (id, email, is_anonymous)
values
  ('00000000-0000-0000-0000-000000000001', 'one@example.test', false),
  ('00000000-0000-0000-0000-000000000002', 'two@example.test', false);
insert into public.profiles (user_id, display_name, is_permanent)
values
  ('00000000-0000-0000-0000-000000000001', 'one', true),
  ('00000000-0000-0000-0000-000000000002', 'two', true);
insert into public.wallets (user_id) values
  ('00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000002');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select is((select count(*) from public.wallets)::bigint, 1::bigint, 'cross-user wallet reads return zero rows');
select throws_ok(
  $$ update public.wallets set royal_jade = 999 $$,
  '42501'
);
select throws_ok(
  $$ insert into public.wallet_ledger
     (user_id, currency_code, delta, balance_after, reason,
      reference_type, reference_id, idempotency_key)
     values (auth.uid(), 'royal_jade', 1, 1, 'hack', 'test', '1', 'hack') $$,
  '42501'
);
reset role;

set local role service_role;
select lives_ok($$ select * from private.apply_wallet_entry(
  '00000000-0000-0000-0000-000000000001', 100, 'purchase', 'test', 'grant-1', 'grant-1', '{}') $$,
  'trusted grant succeeds');
select lives_ok($$ select * from private.apply_wallet_entry(
  '00000000-0000-0000-0000-000000000001', 100, 'purchase', 'test', 'grant-1', 'grant-1', '{}') $$,
  'duplicate idempotency key is accepted');
select is((select royal_jade from public.wallets where user_id = '00000000-0000-0000-0000-000000000001'), 100::bigint, 'duplicate idempotency key grants once');

select lives_ok($$ select * from private.record_google_play_purchase(
  '00000000-0000-0000-0000-000000000001', 'royal_jade_small', 'token-1', 'order-1', 'PURCHASED', '{}') $$,
  'verified purchase grants');
select lives_ok($$ select * from private.record_google_play_purchase(
  '00000000-0000-0000-0000-000000000001', 'royal_jade_small', 'token-1', 'order-1', 'PURCHASED', '{}') $$,
  'duplicate purchase token is accepted');
select is((select count(*) from private.google_play_purchases where purchase_token = 'token-1'), 1::bigint, 'duplicate purchase token records once');
select is((select royal_jade from public.wallets where user_id = '00000000-0000-0000-0000-000000000001'), 200::bigint, 'duplicate purchase token grants once');

reset role;
insert into private.premium_catalog (sku, royal_jade_price, entitlement_key, active)
values ('test_cosmetic', 75, 'cosmetic.test', true),
       ('inactive_cosmetic', 1, 'cosmetic.inactive', false);
set local role service_role;
select throws_ok($$ select * from private.spend_for_entitlement('00000000-0000-0000-0000-000000000001', 'unknown') $$, 'P0001', 'unknown_sku');
select throws_ok($$ select * from private.spend_for_entitlement('00000000-0000-0000-0000-000000000001', 'inactive_cosmetic') $$, 'P0001', 'inactive_sku');
select lives_ok($$ select * from private.spend_for_entitlement('00000000-0000-0000-0000-000000000001', 'test_cosmetic') $$, 'active SKU spends');
select lives_ok($$ select * from private.spend_for_entitlement('00000000-0000-0000-0000-000000000001', 'test_cosmetic') $$, 'duplicate entitlement is idempotent');
select is((select count(*) from public.player_entitlements where user_id = '00000000-0000-0000-0000-000000000001' and entitlement_key = 'cosmetic.test'), 1::bigint, 'entitlement is granted once');
select throws_ok($$ select * from private.spend_for_entitlement('00000000-0000-0000-0000-000000000002', 'test_cosmetic') $$, 'P0001', 'insufficient_funds');
select is((select count(*) from public.player_entitlements where user_id = '00000000-0000-0000-0000-000000000002'), 0::bigint, 'insufficient spend rolls back entitlement');

select lives_ok($$ select * from private.apply_wallet_entry(
  '00000000-0000-0000-0000-000000000001', -200, 'refund', 'purchase', 'token-1', 'refund-token-1', '{}') $$,
  'refund creates debt for shortfall');
select lives_ok($$ select * from private.apply_wallet_entry(
  '00000000-0000-0000-0000-000000000001', 100, 'purchase', 'test', 'grant-2', 'grant-2', '{}') $$,
  'later grant settles debt first');
select results_eq(
  $$ select royal_jade, royal_jade_debt from public.wallets where user_id = '00000000-0000-0000-0000-000000000001' $$,
  $$ values (25::bigint, 0::bigint) $$,
  'refund debt settles before a later grant');

select throws_ok($$ update public.wallet_ledger set reason = 'tamper' $$, '42501');
select throws_ok($$ delete from public.wallet_ledger $$, '42501');
reset role;

select * from finish();
rollback;
