begin;

-- Production telemetry on 2026-10-15 showed POST /api/visits failing with
-- PGRST204 because planning_note was missing from public.visits. This
-- forward-only repair is safe both when 0030 was skipped and when it already
-- ran; it intentionally preserves existing visit data.
alter table public.visits
  add column if not exists visit_type text,
  add column if not exists planning_note text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.visits'::regclass
      and conname = 'visits_visit_type_check'
  ) then
    alter table public.visits
      add constraint visits_visit_type_check
      check (
        visit_type is null or visit_type in (
          'sales_meeting',
          'quote_follow_up',
          'order_follow_up',
          'introduction',
          'technical',
          'other'
        )
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.visits'::regclass
      and conname = 'visits_planning_note_check'
  ) then
    alter table public.visits
      add constraint visits_planning_note_check
      check (planning_note is null or char_length(planning_note) <= 2000);
  end if;
end;
$$;

commit;
