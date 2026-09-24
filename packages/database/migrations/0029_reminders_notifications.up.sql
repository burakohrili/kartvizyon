begin;

alter table public.notifications
  add column occurrence_key text;

create unique index notifications_user_occurrence_key_idx
  on public.notifications(user_id, occurrence_key)
  where occurrence_key is not null;

create index notifications_workspace_user_created_idx
  on public.notifications(workspace_id, user_id, created_at desc);

create table public.notification_preferences (
  user_id uuid not null references public.profiles(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  visit_reminders boolean not null default true,
  task_reminders boolean not null default true,
  field_mode_morning boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (user_id, workspace_id)
);

alter table public.notification_preferences enable row level security;

revoke all on public.notification_preferences from anon, authenticated;
grant select, insert, update on public.notification_preferences to authenticated;

create policy notification_preferences_owner_read on public.notification_preferences for select
  using (user_id = auth.uid() and public.can_access_workspace(workspace_id));

create policy notification_preferences_owner_insert on public.notification_preferences for insert
  with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));

create policy notification_preferences_owner_update on public.notification_preferences for update
  using (user_id = auth.uid() and public.can_access_workspace(workspace_id))
  with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));

-- Notification records are domain output. Authenticated clients may read their
-- own rows and mark them read, but cannot manufacture arbitrary notifications.
drop policy notifications_owner_all on public.notifications;
create policy notifications_owner_read on public.notifications for select
  using (user_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy notifications_owner_update on public.notifications for update
  using (user_id = auth.uid() and public.can_access_workspace(workspace_id))
  with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));

revoke insert, delete, update on public.notifications from authenticated;
grant update(read_at) on public.notifications to authenticated;

create index visits_reminder_window_idx
  on public.visits(planned_start_at, representative_id)
  where planned_start_at is not null and completed_at is null;
create index visits_missed_window_idx
  on public.visits(planned_end_at, representative_id)
  where planned_end_at is not null and completed_at is null;

create or replace function public.process_reminders(
  worker_now timestamptz default now(),
  batch_limit integer default 500
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  inserted_count integer := 0;
  affected integer := 0;
begin
  batch_limit := least(greatest(batch_limit, 1), 1000);

  -- Each reminder remains eligible until the next reminder boundary. This
  -- catches delayed cron runs; semantic keys keep concurrent retries atomic.
  with candidates as (
    select v.*, coalesce(p.timezone, 'UTC') as user_timezone,
      c.name as company_name, reminder.offset_label
    from public.visits v
    join public.companies c on c.id = v.company_id
    join public.profiles p on p.id = v.representative_id
    cross join (values (interval '24 hours', '24h'), (interval '2 hours', '2h')) reminder(offset_value, offset_label)
    left join public.notification_preferences pref
      on pref.user_id = v.representative_id and pref.workspace_id = v.workspace_id
    where v.planned_start_at is not null
      and v.completed_at is null
      and v.status not in ('approved', 'rejected', 'archived')
      and coalesce(pref.visit_reminders, true)
      and worker_now >= v.planned_start_at - reminder.offset_value
      and worker_now < case reminder.offset_label
        when '24h' then v.planned_start_at - interval '2 hours'
        else v.planned_start_at
      end
    order by v.planned_start_at
    limit batch_limit
  )
  insert into public.notifications (
    workspace_id, organization_id, user_id, type, title, body,
    resource_type, resource_id, action_url, occurrence_key
  )
  select workspace_id, organization_id, representative_id, 'visit_upcoming',
    'Yaklaşan ziyaret',
    company_name || ' ziyaretiniz ' || case offset_label when '24h' then '24 saat' else '2 saat' end || ' sonra.',
    'visit', id::text, '/visits',
    'visit:' || id::text || ':upcoming:' || offset_label || ':' || extract(epoch from planned_start_at)::bigint::text
  from candidates
  on conflict (user_id, occurrence_key) where occurrence_key is not null do nothing;
  get diagnostics affected = row_count;
  inserted_count := inserted_count + affected;

  -- A 30-minute tolerance avoids declaring a visit missed while notes or
  -- check-out are still being completed.
  with candidates as (
    select v.*, c.name as company_name
    from public.visits v
    join public.companies c on c.id = v.company_id
    left join public.notification_preferences pref
      on pref.user_id = v.representative_id and pref.workspace_id = v.workspace_id
    where v.planned_end_at is not null
      and v.planned_end_at + interval '30 minutes' <= worker_now
      and v.completed_at is null
      and v.status not in ('approved', 'rejected', 'archived')
      and coalesce(pref.visit_reminders, true)
    order by v.planned_end_at
    limit batch_limit
  )
  insert into public.notifications (
    workspace_id, organization_id, user_id, type, title, body,
    resource_type, resource_id, action_url, occurrence_key
  )
  select workspace_id, organization_id, representative_id, 'visit_missed',
    'Ziyaret tamamlanmadı', company_name || ' ziyaretiniz tamamlanmış görünmüyor.',
    'visit', id::text, '/visits',
    'visit:' || id::text || ':missed:' || extract(epoch from planned_end_at)::bigint::text
  from candidates
  on conflict (user_id, occurrence_key) where occurrence_key is not null do nothing;
  get diagnostics affected = row_count;
  inserted_count := inserted_count + affected;

  with candidates as (
    select t.*, coalesce(p.timezone, 'UTC') as user_timezone
    from public.tasks t
    join public.profiles p on p.id = t.assigned_to
    left join public.notification_preferences pref
      on pref.user_id = t.assigned_to and pref.workspace_id = t.workspace_id
    where t.status = 'open' and t.due_at is not null
      and coalesce(pref.task_reminders, true)
      and (t.due_at at time zone coalesce(p.timezone, 'UTC'))::date =
          (worker_now at time zone coalesce(p.timezone, 'UTC'))::date
      and (worker_now at time zone coalesce(p.timezone, 'UTC'))::time >= time '08:30'
    order by t.due_at
    limit batch_limit
  )
  insert into public.notifications (
    workspace_id, organization_id, user_id, type, title, body,
    resource_type, resource_id, action_url, occurrence_key
  )
  select workspace_id, organization_id, assigned_to, 'task_due_today',
    'Bugünkü görev', 'Bugün: ' || title, 'task', id::text, '/tasks',
    'task:' || id::text || ':due-today:' || (due_at at time zone user_timezone)::date::text
  from candidates
  on conflict (user_id, occurrence_key) where occurrence_key is not null do nothing;
  get diagnostics affected = row_count;
  inserted_count := inserted_count + affected;

  with candidates as (
    select t.*
    from public.tasks t
    left join public.notification_preferences pref
      on pref.user_id = t.assigned_to and pref.workspace_id = t.workspace_id
    where t.status = 'open' and t.assigned_to is not null
      and t.due_at < worker_now
      and coalesce(pref.task_reminders, true)
    order by t.due_at
    limit batch_limit
  )
  insert into public.notifications (
    workspace_id, organization_id, user_id, type, title, body,
    resource_type, resource_id, action_url, occurrence_key
  )
  select workspace_id, organization_id, assigned_to, 'task_overdue',
    'Gecikmiş görev', 'Gecikmiş görev: ' || title, 'task', id::text, '/tasks',
    'task:' || id::text || ':overdue'
  from candidates
  on conflict (user_id, occurrence_key) where occurrence_key is not null do nothing;
  get diagnostics affected = row_count;
  inserted_count := inserted_count + affected;

  -- Field Mode state is device-local. The worker only states the reliable
  -- server fact: the representative has visits today.
  with candidates as (
    select v.workspace_id, v.organization_id, v.representative_id,
      (worker_now at time zone coalesce(p.timezone, 'UTC'))::date as local_day,
      count(*) as visit_count
    from public.visits v
    join public.profiles p on p.id = v.representative_id
    left join public.notification_preferences pref
      on pref.user_id = v.representative_id and pref.workspace_id = v.workspace_id
    where v.planned_start_at is not null and v.planned_start_at > worker_now
      and v.completed_at is null
      and v.status not in ('approved', 'rejected', 'archived')
      and coalesce(pref.field_mode_morning, true)
      and (v.planned_start_at at time zone coalesce(p.timezone, 'UTC'))::date =
          (worker_now at time zone coalesce(p.timezone, 'UTC'))::date
      and (worker_now at time zone coalesce(p.timezone, 'UTC'))::time >= time '08:30'
      and (worker_now at time zone coalesce(p.timezone, 'UTC'))::time < time '12:00'
    group by v.workspace_id, v.organization_id, v.representative_id,
      (worker_now at time zone coalesce(p.timezone, 'UTC'))::date
    order by v.representative_id
    limit batch_limit
  )
  insert into public.notifications (
    workspace_id, organization_id, user_id, type, title, body,
    resource_type, action_url, occurrence_key
  )
  select workspace_id, organization_id, representative_id, 'field_mode_morning',
    'Bugünün saha planı', 'Bugün ' || visit_count || ' planlı ziyaretiniz var.',
    'field_mode', '/', 'field-mode:' || representative_id::text || ':' || local_day::text
  from candidates
  on conflict (user_id, occurrence_key) where occurrence_key is not null do nothing;
  get diagnostics affected = row_count;
  inserted_count := inserted_count + affected;

  return jsonb_build_object('created', inserted_count, 'processedAt', worker_now);
end;
$$;

revoke all on function public.process_reminders(timestamptz, integer) from public, anon, authenticated;
grant execute on function public.process_reminders(timestamptz, integer) to service_role;

commit;
