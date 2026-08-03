begin;

create type public.import_status as enum ('uploaded', 'previewed', 'processing', 'completed', 'failed', 'rolled_back');

create table public.import_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  created_by uuid not null references public.profiles(id),
  file_name text not null,
  file_hash text not null,
  file_size bigint not null check (file_size > 0 and file_size <= 10485760),
  status public.import_status not null default 'uploaded',
  column_mapping jsonb not null default '{}'::jsonb,
  total_rows integer not null default 0,
  imported_rows integer not null default 0,
  skipped_rows integer not null default 0,
  error_rows jsonb not null default '[]'::jsonb,
  created_company_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  rolled_back_at timestamptz,
  unique (workspace_id, file_hash)
);

create index import_jobs_scope_time_idx on public.import_jobs(workspace_id, created_at desc);
alter table public.import_jobs enable row level security;

create policy import_jobs_scope_read on public.import_jobs for select using (public.can_access_workspace(workspace_id));
create policy import_jobs_owner_insert on public.import_jobs for insert with check (public.can_access_workspace(workspace_id) and created_by = auth.uid());
create policy import_jobs_owner_update on public.import_jobs for update using (public.can_access_workspace(workspace_id) and created_by = auth.uid()) with check (public.can_access_workspace(workspace_id) and created_by = auth.uid());

commit;
