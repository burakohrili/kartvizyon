begin;

drop index if exists documents_workspace_purpose_idx;
alter table public.documents drop column if exists purpose;

commit;
