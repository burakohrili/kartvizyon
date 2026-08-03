begin;

create type public.subscription_status as enum ('trialing', 'active', 'past_due', 'cancelled');
create type public.privacy_request_kind as enum ('export', 'deletion');
create type public.privacy_request_status as enum ('requested', 'processing', 'ready', 'completed', 'rejected');

alter table public.usage_records drop constraint if exists usage_records_metric_check;
alter table public.usage_records add constraint usage_records_metric_check
  check (metric in ('audio_seconds', 'input_tokens', 'output_tokens', 'storage_bytes'));

create table public.subscription_plans (
  id text primary key,
  name text not null,
  monthly_price_try numeric(12,2) not null check (monthly_price_try >= 0),
  seat_limit integer not null check (seat_limit > 0),
  monthly_ai_minutes integer not null check (monthly_ai_minutes >= 0),
  monthly_document_bytes bigint not null check (monthly_document_bytes >= 0),
  features jsonb not null default '[]'::jsonb check (jsonb_typeof(features) = 'array'),
  active boolean not null default true
);

insert into public.subscription_plans values
  ('starter', 'Başlangıç', 990, 5, 300, 1073741824, '["Ziyaret ve görev yönetimi", "AI debrief", "Temel raporlar"]'),
  ('growth', 'Büyüme', 2490, 20, 1500, 10737418240, '["Gelişmiş raporlar", "Sipariş taslakları", "Webhook ve API"]'),
  ('enterprise', 'Kurumsal', 0, 500, 10000, 107374182400, '["Özel limitler", "SLA", "Gelişmiş güvenlik"]');

create table public.workspace_subscriptions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null unique references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  plan_id text not null references public.subscription_plans(id),
  status public.subscription_status not null default 'trialing',
  seat_quantity integer not null default 1 check (seat_quantity > 0),
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  current_period_start timestamptz not null default now(),
  current_period_end timestamptz not null default (now() + interval '30 days'),
  cancel_at_period_end boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.api_credentials (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  token_prefix text not null,
  token_hash text not null unique check (token_hash ~ '^[a-f0-9]{64}$'),
  scopes text[] not null check (cardinality(scopes) > 0),
  created_by uuid not null references public.profiles(id),
  last_used_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.webhook_endpoints (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  url text not null check (url ~ '^https://'),
  events text[] not null check (cardinality(events) > 0),
  signing_secret_hash text not null check (signing_secret_hash ~ '^[a-f0-9]{64}$'),
  signing_secret_prefix text not null,
  signing_secret_ciphertext text not null,
  active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.webhook_deliveries (
  id uuid primary key default gen_random_uuid(),
  endpoint_id uuid not null references public.webhook_endpoints(id) on delete cascade,
  event_type text not null,
  event_id uuid not null default gen_random_uuid(),
  resource_id text not null,
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  attempt integer not null default 1 check (attempt between 1 and 10),
  response_status integer,
  error_message text,
  delivered_at timestamptz,
  next_attempt_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.user_consents (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  purpose text not null check (purpose in ('product_analytics', 'ai_processing', 'email_notifications')),
  granted boolean not null,
  policy_version text not null default '2026-08-01',
  recorded_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique (workspace_id, user_id, purpose)
);

create table public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind public.privacy_request_kind not null,
  status public.privacy_request_status not null default 'requested',
  reason text check (char_length(reason) <= 1000),
  export_storage_path text,
  requested_at timestamptz not null default now(),
  due_at timestamptz not null default (now() + interval '30 days'),
  completed_at timestamptz
);

create index api_credentials_workspace_idx on public.api_credentials(workspace_id, created_at desc);
create index webhook_endpoints_workspace_idx on public.webhook_endpoints(workspace_id, created_at desc);
create index privacy_requests_user_idx on public.privacy_requests(user_id, requested_at desc);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('privacy-exports', 'privacy-exports', false, 52428800, array['application/json'])
on conflict (id) do nothing;

create or replace function public.is_workspace_admin(target_workspace_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.workspaces w
    where w.id = target_workspace_id and (
      (w.kind = 'personal' and w.owner_user_id = auth.uid()) or
      (w.kind = 'organization' and public.has_organization_role(w.organization_id, array['owner', 'sales_director']::public.membership_role[]))
    )
  );
$$;

alter table public.subscription_plans enable row level security;
alter table public.workspace_subscriptions enable row level security;
alter table public.api_credentials enable row level security;
alter table public.webhook_endpoints enable row level security;
alter table public.webhook_deliveries enable row level security;
alter table public.user_consents enable row level security;
alter table public.privacy_requests enable row level security;

create policy plans_authenticated_read on public.subscription_plans for select to authenticated using (active);
create policy usage_workspace_admin_read on public.usage_records for select using (public.is_workspace_admin(workspace_id));
create policy subscriptions_scope_read on public.workspace_subscriptions for select using (public.can_access_workspace(workspace_id));
create policy subscriptions_admin_write on public.workspace_subscriptions for all using (public.is_workspace_admin(workspace_id)) with check (public.is_workspace_admin(workspace_id));
create policy credentials_admin_all on public.api_credentials for all using (public.is_workspace_admin(workspace_id)) with check (public.is_workspace_admin(workspace_id) and created_by = auth.uid());
create policy webhooks_admin_all on public.webhook_endpoints for all using (public.is_workspace_admin(workspace_id)) with check (public.is_workspace_admin(workspace_id) and created_by = auth.uid());
create policy deliveries_admin_read on public.webhook_deliveries for select using (exists (select 1 from public.webhook_endpoints e where e.id = endpoint_id and public.is_workspace_admin(e.workspace_id)));
create policy consents_owner_all on public.user_consents for all using (user_id = auth.uid() and public.can_access_workspace(workspace_id)) with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy privacy_owner_all on public.privacy_requests for all using (user_id = auth.uid() and public.can_access_workspace(workspace_id)) with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy privacy_export_owner_read on storage.objects for select to authenticated using (
  bucket_id = 'privacy-exports' and exists (
    select 1 from public.privacy_requests r
    where r.export_storage_path = name and r.user_id = auth.uid() and r.status = 'ready'
  )
);

revoke all on function public.is_workspace_admin(uuid) from public;
grant execute on function public.is_workspace_admin(uuid) to authenticated;

commit;
