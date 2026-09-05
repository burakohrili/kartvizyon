begin;

alter table public.visits drop constraint if exists visit_approval_consistent;
alter table public.visits add constraint visit_approval_consistent check (
  (status = 'approved' and approved_by is not null and approved_at is not null) or
  (status <> 'approved' and approved_by is null and approved_at is null)
);

commit;
