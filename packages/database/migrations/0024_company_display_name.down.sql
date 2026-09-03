begin;

drop index if exists public.companies_workspace_display_name_idx;
alter table public.companies drop column if exists display_name;

commit;
