create extension if not exists pgtap with schema extensions;
create extension if not exists dblink with schema extensions;
select plan(3);

select extensions.dblink_connect('progress_1', 'host=host.docker.internal port=54322 dbname=postgres user=postgres password=postgres');
select extensions.dblink_connect('progress_2', 'host=host.docker.internal port=54322 dbname=postgres user=postgres password=postgres');
select extensions.dblink_exec('progress_1', $setup$
  delete from auth.users where id = '00000000-0000-0000-0000-000000000020';
  insert into auth.users (id, email, is_anonymous)
  values ('00000000-0000-0000-0000-000000000020', 'progress-concurrent@example.test', false);
$setup$);

create or replace function public.test_delay_progress_insert()
returns trigger language plpgsql as $$
begin
  perform pg_sleep(0.5);
  return new;
end;
$$;
create trigger test_delay_progress_insert
before insert on public.player_progress
for each row execute function public.test_delay_progress_insert();

select extensions.dblink_send_query('progress_1',
  $$select revision, applied from private.sync_progress(
    '00000000-0000-0000-0000-000000000020', 3, '{"schemaVersion":3,"writer":"one"}', 0)$$);
select extensions.dblink_send_query('progress_2',
  $$select revision, applied from private.sync_progress(
    '00000000-0000-0000-0000-000000000020', 3, '{"schemaVersion":3,"writer":"two"}', 0)$$);

create temporary table progress_concurrency_results (
  revision bigint not null,
  applied boolean not null
);
insert into progress_concurrency_results
select revision, applied
from extensions.dblink_get_result('progress_1') as result(revision bigint, applied boolean);
insert into progress_concurrency_results
select revision, applied
from extensions.dblink_get_result('progress_2') as result(revision bigint, applied boolean);
select revision, applied
from extensions.dblink_get_result('progress_1') as result(revision bigint, applied boolean);
select revision, applied
from extensions.dblink_get_result('progress_2') as result(revision bigint, applied boolean);

select is((select count(*) from progress_concurrency_results), 2::bigint,
  'both concurrent initial sync calls return a snapshot');
select is((select count(*) from progress_concurrency_results where applied), 1::bigint,
  'one concurrent initial sync creates progress');
select is((select count(*) from progress_concurrency_results where not applied), 1::bigint,
  'the other concurrent initial sync returns the winning snapshot as a conflict');

drop trigger test_delay_progress_insert on public.player_progress;
drop function public.test_delay_progress_insert();
select extensions.dblink_exec('progress_1', $cleanup$
  delete from auth.users where id = '00000000-0000-0000-0000-000000000020';
$cleanup$);
select extensions.dblink_disconnect('progress_1');
select extensions.dblink_disconnect('progress_2');

select * from finish();
