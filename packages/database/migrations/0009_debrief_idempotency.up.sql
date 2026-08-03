begin;

create table public.debrief_submissions (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references public.visits(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  client_mutation_id uuid not null,
  status public.ai_job_status not null default 'processing',
  response jsonb,
  error_code text,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, client_mutation_id)
);

alter table public.debrief_submissions enable row level security;
create policy debrief_submissions_owner_only on public.debrief_submissions for all
using (user_id = auth.uid() and public.can_access_workspace(workspace_id))
with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));

commit;
