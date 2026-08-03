begin;
drop trigger if exists approved_visit_create_tasks on public.visits;
drop function if exists public.create_tasks_from_approved_visit();
drop index if exists public.tasks_ai_follow_up_unique;
alter table public.tasks drop column if exists source_follow_up_index;
alter table public.tasks drop column if exists source;
commit;
