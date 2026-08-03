begin;

delete from storage.buckets where id = 'document-quarantine';

drop policy if exists document_quarantine_owner_delete on storage.objects;
drop policy if exists document_clean_scope_read on storage.objects;
drop policy if exists document_quarantine_owner_insert on storage.objects;
drop function if exists public.create_activity_comment(uuid, text);
drop table if exists public.form_submissions;
drop table if exists public.form_templates;
drop table if exists public.documents;
drop table if exists public.notifications;
drop table if exists public.activity_comments;
drop type if exists public.document_scan_status;

commit;
