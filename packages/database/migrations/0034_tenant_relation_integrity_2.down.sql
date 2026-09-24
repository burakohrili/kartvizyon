begin;

drop trigger if exists notifications_relation_integrity_2 on public.notifications;
drop trigger if exists opportunities_relation_integrity_2 on public.opportunities;
drop trigger if exists form_submissions_relation_integrity_2 on public.form_submissions;
drop trigger if exists documents_relation_integrity_2 on public.documents;
drop function if exists public.enforce_tenant_relation_integrity_2();

commit;
