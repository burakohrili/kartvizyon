begin;

create type public.opportunity_stage as enum ('lead', 'qualified', 'proposal', 'negotiation', 'won', 'lost');
create type public.order_draft_status as enum ('draft', 'pending_approval', 'approved', 'rejected', 'exported', 'cancelled');

create table public.regions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  parent_region_id uuid references public.regions(id) on delete set null,
  name text not null check (char_length(name) between 2 and 120),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (workspace_id, name)
);

alter table public.memberships
  add constraint memberships_region_fk foreign key (region_id) references public.regions(id) on delete set null;

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  region_id uuid references public.regions(id) on delete set null,
  name text not null check (char_length(name) between 2 and 120),
  manager_id uuid references public.profiles(id) on delete set null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  archived_at timestamptz,
  unique (organization_id, name)
);

create table public.team_members (
  team_id uuid not null references public.teams(id) on delete cascade,
  membership_id uuid not null references public.memberships(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (team_id, membership_id)
);

alter table public.visits
  add column planned_start_at timestamptz,
  add column planned_end_at timestamptz,
  add column check_in_type text check (check_in_type in ('gps', 'manual', 'remote')),
  add constraint visit_plan_time_valid check (
    planned_start_at is null or planned_end_at is null or planned_end_at > planned_start_at
  );

create index visits_workspace_plan_idx on public.visits(workspace_id, planned_start_at)
  where planned_start_at is not null;

create table public.opportunities (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  title text not null check (char_length(title) between 2 and 180),
  stage public.opportunity_stage not null default 'lead',
  estimated_value numeric(16,2) not null default 0 check (estimated_value >= 0),
  currency text not null default 'TRY' check (currency in ('TRY', 'USD', 'EUR')),
  probability smallint not null default 10 check (probability between 0 and 100),
  expected_close_date date,
  competitor text,
  loss_reason text,
  assigned_to uuid references public.profiles(id) on delete set null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz
);

create index opportunities_workspace_stage_idx on public.opportunities(workspace_id, stage, expected_close_date);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  sku citext not null,
  name text not null check (char_length(name) between 2 and 180),
  unit text not null default 'adet',
  tax_rate numeric(5,2) not null default 20 check (tax_rate between 0 and 100),
  list_price numeric(16,2) not null check (list_price >= 0),
  currency text not null default 'TRY' check (currency in ('TRY', 'USD', 'EUR')),
  active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, sku)
);

create table public.price_lists (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 160),
  currency text not null default 'TRY' check (currency in ('TRY', 'USD', 'EUR')),
  valid_from date not null,
  valid_to date,
  version integer not null default 1 check (version > 0),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  check (valid_to is null or valid_to >= valid_from),
  unique (workspace_id, name, version)
);

create table public.price_list_items (
  id uuid primary key default gen_random_uuid(),
  price_list_id uuid not null references public.price_lists(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  company_id uuid references public.companies(id) on delete cascade,
  unit_price numeric(16,2) not null check (unit_price >= 0),
  unique nulls not distinct (price_list_id, product_id, company_id)
);

create table public.order_drafts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  company_id uuid not null references public.companies(id),
  opportunity_id uuid references public.opportunities(id) on delete set null,
  status public.order_draft_status not null default 'draft',
  currency text not null default 'TRY' check (currency in ('TRY', 'USD', 'EUR')),
  subtotal numeric(16,2) not null default 0,
  discount_total numeric(16,2) not null default 0,
  tax_total numeric(16,2) not null default 0,
  grand_total numeric(16,2) not null default 0,
  delivery_date date,
  notes text,
  created_by uuid not null references public.profiles(id),
  approved_by uuid references public.profiles(id),
  approved_at timestamptz,
  rejected_reason text,
  external_order_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_draft_items (
  id uuid primary key default gen_random_uuid(),
  order_draft_id uuid not null references public.order_drafts(id) on delete cascade,
  product_id uuid not null references public.products(id),
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price numeric(16,2) not null check (unit_price >= 0),
  discount_percent numeric(5,2) not null default 0 check (discount_percent between 0 and 100),
  tax_rate numeric(5,2) not null check (tax_rate between 0 and 100),
  line_total numeric(16,2) not null check (line_total >= 0)
);

create index order_drafts_workspace_status_idx on public.order_drafts(workspace_id, status, created_at desc);

create or replace function public.recalculate_order_draft(target_order_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  target_workspace_id uuid;
begin
  select workspace_id into target_workspace_id from public.order_drafts where id = target_order_id;
  if not found or not public.can_access_workspace(target_workspace_id) then raise exception 'Sipariş taslağına erişiminiz yok'; end if;
  update public.order_drafts o set
    subtotal = totals.subtotal,
    discount_total = totals.discount_total,
    tax_total = totals.tax_total,
    grand_total = totals.subtotal - totals.discount_total + totals.tax_total,
    updated_at = now()
  from (
    select
      coalesce(sum(i.quantity * i.unit_price), 0) as subtotal,
      coalesce(sum(i.quantity * i.unit_price * i.discount_percent / 100), 0) as discount_total,
      coalesce(sum((i.quantity * i.unit_price * (1 - i.discount_percent / 100)) * i.tax_rate / 100), 0) as tax_total
    from public.order_draft_items i where i.order_draft_id = target_order_id
  ) totals where o.id = target_order_id;
end;
$$;

create or replace function public.transition_order_draft(target_order_id uuid, target_status public.order_draft_status, rejection_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare
  target_order public.order_drafts%rowtype;
begin
  select * into target_order from public.order_drafts where id = target_order_id;
  if not found or not public.can_access_workspace(target_order.workspace_id) then raise exception 'Sipariş taslağına erişiminiz yok'; end if;
  if target_status = 'pending_approval' then
    if target_order.created_by <> auth.uid() or target_order.status <> 'draft' then raise exception 'Sipariş onaya gönderilemez'; end if;
    update public.order_drafts set status = target_status, updated_at = now() where id = target_order_id;
  elsif target_status in ('approved', 'rejected') then
    if target_order.organization_id is null or not public.has_organization_role(target_order.organization_id, array['owner', 'sales_director', 'regional_manager']::public.membership_role[]) then raise exception 'Sipariş onay yetkiniz yok'; end if;
    if target_order.status <> 'pending_approval' then raise exception 'Sipariş onay beklemiyor'; end if;
    update public.order_drafts set status = target_status, approved_by = auth.uid(), approved_at = case when target_status = 'approved' then now() else null end, rejected_reason = case when target_status = 'rejected' then rejection_reason else null end, updated_at = now() where id = target_order_id;
  else
    raise exception 'Geçersiz durum geçişi';
  end if;
  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id, metadata)
  values (target_order.organization_id, target_order.workspace_id, auth.uid(), 'order.' || target_status::text, 'order_draft', target_order_id::text, jsonb_build_object('from', target_order.status, 'to', target_status));
end;
$$;

alter table public.regions enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.opportunities enable row level security;
alter table public.products enable row level security;
alter table public.price_lists enable row level security;
alter table public.price_list_items enable row level security;
alter table public.order_drafts enable row level security;
alter table public.order_draft_items enable row level security;

create policy regions_scope_all on public.regions for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy teams_scope_all on public.teams for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy team_members_scope_all on public.team_members for all using (exists (select 1 from public.teams t where t.id = team_id and public.can_access_workspace(t.workspace_id))) with check (exists (select 1 from public.teams t where t.id = team_id and public.can_access_workspace(t.workspace_id)));
create policy opportunities_scope_all on public.opportunities for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy products_scope_all on public.products for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy price_lists_scope_all on public.price_lists for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy price_list_items_scope_all on public.price_list_items for all using (exists (select 1 from public.price_lists p where p.id = price_list_id and public.can_access_workspace(p.workspace_id))) with check (exists (select 1 from public.price_lists p where p.id = price_list_id and public.can_access_workspace(p.workspace_id)));
create policy order_drafts_scope_all on public.order_drafts for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy order_items_scope_all on public.order_draft_items for all using (exists (select 1 from public.order_drafts o where o.id = order_draft_id and public.can_access_workspace(o.workspace_id))) with check (exists (select 1 from public.order_drafts o where o.id = order_draft_id and public.can_access_workspace(o.workspace_id)));

revoke all on function public.recalculate_order_draft(uuid) from public;
revoke all on function public.transition_order_draft(uuid, public.order_draft_status, text) from public;
grant execute on function public.recalculate_order_draft(uuid) to authenticated;
grant execute on function public.transition_order_draft(uuid, public.order_draft_status, text) to authenticated;

commit;
