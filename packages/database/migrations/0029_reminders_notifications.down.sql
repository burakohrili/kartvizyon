begin;

drop function if exists public.process_reminders(timestamptz, integer);
drop index if exists public.visits_missed_window_idx;
drop index if exists public.visits_reminder_window_idx;

drop policy if exists notifications_owner_update on public.notifications;
drop policy if exists notifications_owner_read on public.notifications;
grant insert, delete, update on public.notifications to authenticated;
create policy notifications_owner_all on public.notifications for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke all on public.notification_preferences from authenticated;
drop table if exists public.notification_preferences;
drop index if exists public.notifications_workspace_user_created_idx;
drop index if exists public.notifications_user_occurrence_key_idx;
alter table public.notifications drop column if exists occurrence_key;

commit;
