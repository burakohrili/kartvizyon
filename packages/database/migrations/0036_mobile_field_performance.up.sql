begin;

-- `route_key` is both a PL/pgSQL parameter and a table column. The inferred
-- ON CONFLICT column list is ambiguous in deployed Postgres. Naming the PK
-- constraint avoids shadowing and keeps the existing RPC signature intact.
create or replace function public.consume_api_rate_limit(route_key text, request_limit integer default 120, window_seconds integer default 60)
returns boolean language plpgsql security definer set search_path = '' as $$
declare
  allowed boolean;
begin
  if auth.uid() is null then return false; end if;
  if request_limit < 1 or request_limit > 10000 or window_seconds < 1 or window_seconds > 86400 then
    raise exception 'Geçersiz hız limiti';
  end if;
  insert into public.api_rate_limits (user_id, route_key, window_start, request_count)
  values (auth.uid(), left(route_key, 240), now(), 1)
  on conflict on constraint api_rate_limits_pkey do update set
    window_start = case when public.api_rate_limits.window_start < now() - make_interval(secs => window_seconds) then now() else public.api_rate_limits.window_start end,
    request_count = case when public.api_rate_limits.window_start < now() - make_interval(secs => window_seconds) then 1 else public.api_rate_limits.request_count + 1 end
  returning request_count <= request_limit into allowed;
  return allowed;
end;
$$;

-- Mobile task lists order by due date within a workspace; the previous index
-- began with assigned_to and could not efficiently serve that access pattern.
create index tasks_workspace_due_id_idx
  on public.tasks (workspace_id, due_at asc nulls last, id asc);

commit;
