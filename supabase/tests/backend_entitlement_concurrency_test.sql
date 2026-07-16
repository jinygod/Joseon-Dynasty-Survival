create extension if not exists pgtap with schema extensions;
create extension if not exists dblink with schema extensions;
select plan(2);

select extensions.dblink_connect('entitlement_1', 'host=host.docker.internal port=54322 dbname=postgres user=postgres password=postgres');
select extensions.dblink_connect('entitlement_2', 'host=host.docker.internal port=54322 dbname=postgres user=postgres password=postgres');
select extensions.dblink_exec('entitlement_1', $setup$
  delete from auth.users where id = '00000000-0000-0000-0000-000000000010';
  delete from public.wallet_ledger where idempotency_key in (
    'concurrent-grant',
    'entitlement:00000000-0000-0000-0000-000000000010:cosmetic.concurrent');
  delete from private.premium_catalog where sku = 'concurrent_cosmetic';
  insert into auth.users (id, email, is_anonymous)
  values ('00000000-0000-0000-0000-000000000010', 'concurrent@example.test', false);
  insert into private.premium_catalog (sku, royal_jade_price, entitlement_key, active)
  values ('concurrent_cosmetic', 75, 'cosmetic.concurrent', true);
  do $do$
  begin
    perform * from private.apply_wallet_entry(
      '00000000-0000-0000-0000-000000000010', 100, 'test_grant', 'test',
      'concurrent-grant', 'concurrent-grant', '{}');
  end
  $do$;
$setup$);
select extensions.dblink_send_query('entitlement_1',
  $$select duplicate from private.spend_for_entitlement(
    '00000000-0000-0000-0000-000000000010', 'concurrent_cosmetic')$$);
select extensions.dblink_send_query('entitlement_2',
  $$select duplicate from private.spend_for_entitlement(
    '00000000-0000-0000-0000-000000000010', 'concurrent_cosmetic')$$);

create temporary table entitlement_concurrency_results (duplicate boolean not null);
insert into entitlement_concurrency_results
select duplicate from extensions.dblink_get_result('entitlement_1') as result(duplicate boolean);
insert into entitlement_concurrency_results
select duplicate from extensions.dblink_get_result('entitlement_2') as result(duplicate boolean);
select duplicate from extensions.dblink_get_result('entitlement_1') as result(duplicate boolean);
select duplicate from extensions.dblink_get_result('entitlement_2') as result(duplicate boolean);

select is((select count(*) from entitlement_concurrency_results where not duplicate), 1::bigint,
  'one concurrent entitlement request spends');
select is((select count(*) from entitlement_concurrency_results where duplicate), 1::bigint,
  'the other concurrent entitlement request returns duplicate');

select extensions.dblink_exec('entitlement_1', $cleanup$
  delete from auth.users where id = '00000000-0000-0000-0000-000000000010';
  delete from public.wallet_ledger where idempotency_key in (
    'concurrent-grant',
    'entitlement:00000000-0000-0000-0000-000000000010:cosmetic.concurrent');
  delete from private.premium_catalog where sku = 'concurrent_cosmetic';
$cleanup$);
select extensions.dblink_disconnect('entitlement_1');
select extensions.dblink_disconnect('entitlement_2');

select * from finish();
