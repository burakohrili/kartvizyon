begin;

alter table public.visits
  add column visit_type text check (
    visit_type is null or visit_type in (
      'sales_meeting',
      'quote_follow_up',
      'order_follow_up',
      'introduction',
      'technical',
      'other'
    )
  ),
  add column planning_note text check (
    planning_note is null or char_length(planning_note) <= 2000
  );

commit;
