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

  -- A missing row cannot be locked with SELECT ... FOR UPDATE. Serialize all
  -- syncs for one user so concurrent initial uploads deterministically become
  -- one create and one revision conflict instead of a unique-key failure.
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));
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
