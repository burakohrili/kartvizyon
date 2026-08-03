begin;

create table public.geofence_events (
  id bigint generated always as identity primary key,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  priority_score smallint not null check (priority_score between 0 and 100),
  distance_meters integer not null check (distance_meters >= 0),
  outcome text not null check (outcome in ('shown', 'briefing_opened', 'navigation_opened', 'dismissed')),
  occurred_at timestamptz not null default now()
);

create index geofence_events_cooldown_idx on public.geofence_events(user_id, company_id, occurred_at desc);
alter table public.geofence_events enable row level security;
create policy geofence_events_self_all on public.geofence_events for all using (user_id = auth.uid() and public.can_access_workspace(workspace_id)) with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));

commit;
