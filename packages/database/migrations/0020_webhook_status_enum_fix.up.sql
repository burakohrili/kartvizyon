begin;

create or replace function public.enqueue_webhook_event()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  event_name text;
  target_workspace uuid;
  event_uuid uuid := gen_random_uuid();
  event_payload jsonb;
begin
  target_workspace := new.workspace_id;
  if tg_table_name = 'visits' and new.status::text = 'approved' and old.status::text is distinct from new.status::text then
    event_name := 'visit.approved';
  elsif tg_table_name = 'tasks' and new.status::text = 'completed' and old.status::text is distinct from new.status::text then
    event_name := 'task.completed';
  elsif tg_table_name = 'order_drafts' and new.status::text = 'approved' and old.status::text is distinct from new.status::text then
    event_name := 'order.approved';
  else
    return new;
  end if;
  event_payload := jsonb_build_object(
    'id', event_uuid,
    'type', event_name,
    'resourceId', new.id,
    'occurredAt', now(),
    'data', jsonb_build_object('id', new.id, 'status', new.status)
  );
  insert into public.webhook_deliveries (endpoint_id, event_type, event_id, resource_id, payload, next_attempt_at)
  select id, event_name, event_uuid, new.id::text, event_payload, now()
  from public.webhook_endpoints
  where workspace_id = target_workspace and active and event_name = any(events);
  return new;
end;
$$;

commit;
