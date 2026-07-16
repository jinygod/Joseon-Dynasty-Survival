begin;
create extension if not exists pgtap with schema extensions;
select plan(1);

insert into auth.users (id, email, is_anonymous)
values ('00000000-0000-0000-0000-000000000021', 'progress-size@example.test', false);

set local role service_role;
select lives_ok($$
  select * from private.sync_progress(
    '00000000-0000-0000-0000-000000000021',
    3,
    jsonb_build_object(
      'schemaVersion', 3,
      'claimedRewardIds',
      (select jsonb_agg('r' || id) from generate_series(1, 7400) as ids(id))
    ),
    0
  )
$$, 'SQL accepts progress below the Edge compact JSON byte limit');

select * from finish();
rollback;
