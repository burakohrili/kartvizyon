begin;
drop trigger if exists visit_status_audit on public.visits;
drop function if exists public.audit_visit_status_change();
commit;
