begin;

create extension if not exists pgcrypto;
create extension if not exists citext;
create extension if not exists pg_trgm;

create type public.workspace_kind as enum ('personal', 'organization');
create type public.membership_role as enum ('owner', 'sales_director', 'regional_manager', 'team_lead', 'field_sales', 'report_viewer', 'integration_manager');
create type public.record_status as enum ('draft', 'processing', 'needs_review', 'approved', 'rejected', 'archived');
create type public.invitation_status as enum ('pending', 'accepted', 'revoked', 'expired');
create type public.task_status as enum ('open', 'completed', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 2 and 120),
  locale text not null default 'tr' check (locale in ('tr', 'en')),
  timezone text not null default 'Europe/Istanbul',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 160),
  slug citext not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  owner_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  kind public.workspace_kind not null,
  name text not null check (char_length(name) between 2 and 160),
  owner_user_id uuid references public.profiles(id),
  organization_id uuid references public.organizations(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint workspace_owner_matches_kind check (
    (kind = 'personal' and owner_user_id is not null and organization_id is null) or
    (kind = 'organization' and owner_user_id is null and organization_id is not null)
  )
);

create unique index one_personal_workspace_per_user on public.workspaces(owner_user_id) where kind = 'personal';
create unique index one_workspace_per_organization on public.workspaces(organization_id) where kind = 'organization';

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.membership_role not null,
  region_id uuid,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique (organization_id, user_id)
);

create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  email citext not null,
  role public.membership_role not null,
  token_hash text not null unique,
  status public.invitation_status not null default 'pending',
  invited_by uuid not null references public.profiles(id),
  expires_at timestamptz not null,
  accepted_by uuid references public.profiles(id),
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > created_at)
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 200),
  normalized_name text generated always as (lower(regexp_replace(name, '[^[:alnum:]]', '', 'g'))) stored,
  phone text,
  email citext,
  website text,
  address text,
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  assigned_to uuid references public.profiles(id),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  constraint company_scope_matches_workspace check (
    (organization_id is null) or (organization_id is not null)
  )
);

create index companies_workspace_name_idx on public.companies(workspace_id, normalized_name);
create index companies_organization_idx on public.companies(organization_id) where organization_id is not null;

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  first_name text not null,
  last_name text,
  title text,
  phone text,
  email citext,
  preferred_channel text check (preferred_channel in ('phone', 'whatsapp', 'email')),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index contacts_company_idx on public.contacts(company_id);
create index contacts_email_idx on public.contacts(workspace_id, email) where email is not null;

create table public.visits (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  representative_id uuid not null references public.profiles(id),
  client_mutation_id uuid not null,
  status public.record_status not null default 'draft',
  purpose text,
  manual_notes text,
  ai_summary jsonb,
  ai_schema_version text,
  approved_by uuid references public.profiles(id),
  approved_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  check_in_latitude numeric(9, 6),
  check_in_longitude numeric(9, 6),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint visit_approval_consistent check (
    (status = 'approved' and approved_by is not null and approved_at is not null) or
    (status <> 'approved' and approved_by is null and approved_at is null)
  ),
  unique (representative_id, client_mutation_id)
);

create index visits_workspace_status_idx on public.visits(workspace_id, status, completed_at desc);
create index visits_manager_feed_idx on public.visits(organization_id, approved_at desc) where status = 'approved';

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  company_id uuid references public.companies(id) on delete cascade,
  visit_id uuid references public.visits(id) on delete set null,
  title text not null check (char_length(title) between 1 and 180),
  status public.task_status not null default 'open',
  due_at timestamptz,
  assigned_to uuid references public.profiles(id),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index tasks_assignee_status_idx on public.tasks(assigned_to, status, due_at);

create table public.customer_memory_cards (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null unique references public.companies(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  summary text not null,
  open_promises jsonb not null default '[]'::jsonb,
  source_visit_ids uuid[] not null default '{}',
  generated_at timestamptz not null,
  stale_after timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  organization_id uuid references public.organizations(id) on delete restrict,
  workspace_id uuid not null references public.workspaces(id) on delete restrict,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  resource_type text not null,
  resource_id text,
  metadata jsonb not null default '{}'::jsonb,
  ip_hash text,
  created_at timestamptz not null default now()
);

create index audit_logs_scope_time_idx on public.audit_logs(workspace_id, created_at desc);

create or replace function public.is_organization_member(target_organization_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.memberships m
    where m.organization_id = target_organization_id
      and m.user_id = auth.uid()
      and m.revoked_at is null
  );
$$;

create or replace function public.has_organization_role(target_organization_id uuid, allowed_roles public.membership_role[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.memberships m
    where m.organization_id = target_organization_id
      and m.user_id = auth.uid()
      and m.revoked_at is null
      and m.role = any(allowed_roles)
  );
$$;

create or replace function public.can_access_workspace(target_workspace_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.workspaces w
    where w.id = target_workspace_id
      and (
        (w.kind = 'personal' and w.owner_user_id = auth.uid()) or
        (w.kind = 'organization' and public.is_organization_member(w.organization_id))
      )
  );
$$;

grant execute on function public.is_organization_member(uuid) to authenticated;
grant execute on function public.has_organization_role(uuid, public.membership_role[]) to authenticated;
grant execute on function public.can_access_workspace(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.workspaces enable row level security;
alter table public.memberships enable row level security;
alter table public.invitations enable row level security;
alter table public.companies enable row level security;
alter table public.contacts enable row level security;
alter table public.visits enable row level security;
alter table public.tasks enable row level security;
alter table public.customer_memory_cards enable row level security;
alter table public.audit_logs enable row level security;

create policy profiles_self_read on public.profiles for select using (id = auth.uid());
create policy profiles_self_update on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy organizations_member_read on public.organizations for select using (public.is_organization_member(id));
create policy workspaces_scope_read on public.workspaces for select using (public.can_access_workspace(id));
create policy memberships_member_read on public.memberships for select using (public.is_organization_member(organization_id));
create policy invitations_admin_all on public.invitations for all using (
  public.has_organization_role(organization_id, array['owner', 'sales_director']::public.membership_role[])
) with check (
  public.has_organization_role(organization_id, array['owner', 'sales_director']::public.membership_role[])
);

create policy companies_scope_read on public.companies for select using (public.can_access_workspace(workspace_id));
create policy companies_scope_insert on public.companies for insert with check (public.can_access_workspace(workspace_id) and created_by = auth.uid());
create policy companies_scope_update on public.companies for update using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy contacts_scope_all on public.contacts for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy visits_own_or_approved_read on public.visits for select using (
  public.can_access_workspace(workspace_id) and (organization_id is null or representative_id = auth.uid() or status = 'approved')
);
create policy visits_representative_write on public.visits for all using (representative_id = auth.uid() and public.can_access_workspace(workspace_id)) with check (representative_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy tasks_scope_all on public.tasks for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy memory_cards_scope_read on public.customer_memory_cards for select using (public.can_access_workspace(workspace_id));
create policy audit_logs_scope_read on public.audit_logs for select using (
  public.can_access_workspace(workspace_id) and (
    organization_id is null or public.has_organization_role(organization_id, array['owner', 'sales_director', 'regional_manager']::public.membership_role[])
  )
);

commit;
