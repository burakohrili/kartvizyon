begin;

alter table public.companies
  add column display_name text
  check (display_name is null or char_length(display_name) between 2 and 80);

create index companies_workspace_display_name_idx
  on public.companies (
    workspace_id,
    lower(regexp_replace(coalesce(display_name, ''), '[^[:alnum:]]', '', 'g'))
  )
  where display_name is not null;

commit;
