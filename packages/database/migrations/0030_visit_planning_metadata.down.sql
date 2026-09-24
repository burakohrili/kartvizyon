begin;

alter table public.visits
  drop column if exists planning_note,
  drop column if exists visit_type;

commit;
