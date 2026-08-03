begin;

create table public.api_rate_limits (
  user_id uuid not null references public.profiles(id) on delete cascade,
  route_key text not null,
  window_start timestamptz not null,
  request_count integer not null default 0,
  primary key (user_id, route_key)
);

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
  on conflict (user_id, route_key) do update set
    window_start = case when public.api_rate_limits.window_start < now() - make_interval(secs => window_seconds) then now() else public.api_rate_limits.window_start end,
    request_count = case when public.api_rate_limits.window_start < now() - make_interval(secs => window_seconds) then 1 else public.api_rate_limits.request_count + 1 end
  returning request_count <= request_limit into allowed;
  return allowed;
end;
$$;

create or replace function public.enqueue_webhook_event()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  event_name text;
  target_workspace uuid;
  event_uuid uuid := gen_random_uuid();
  event_payload jsonb;
begin
  target_workspace := new.workspace_id;
  if tg_table_name = 'visits' and new.status = 'approved' and old.status is distinct from new.status then event_name := 'visit.approved';
  elsif tg_table_name = 'tasks' and new.status = 'completed' and old.status is distinct from new.status then event_name := 'task.completed';
  elsif tg_table_name = 'order_drafts' and new.status = 'approved' and old.status is distinct from new.status then event_name := 'order.approved';
  else return new;
  end if;
  event_payload := jsonb_build_object(
    'id', event_uuid,
    'type', event_name,
    'resourceId', new.id,
    'occurredAt', now(),
    'data', jsonb_build_object('id', new.id, 'status', new.status)
  );
  insert into public.webhook_deliveries (endpoint_id, event_type, event_id, resource_id, payload, next_attempt_at)
  select id, event_name, event_uuid, new.id::text, event_payload, now() from public.webhook_endpoints
  where workspace_id = target_workspace and active and event_name = any(events);
  return new;
end;
$$;

create trigger visits_webhook_events after update of status on public.visits for each row execute function public.enqueue_webhook_event();
create trigger tasks_webhook_events after update of status on public.tasks for each row execute function public.enqueue_webhook_event();
create trigger orders_webhook_events after update of status on public.order_drafts for each row execute function public.enqueue_webhook_event();

alter table public.api_rate_limits enable row level security;
revoke all on function public.consume_api_rate_limit(text, integer, integer) from public;
grant execute on function public.consume_api_rate_limit(text, integer, integer) to authenticated;

commit;
