begin;

drop index if exists companies_workspace_location_idx;
alter table public.companies drop column if exists location_updated_at;
alter table public.companies drop column if exists location_source;

commit;
