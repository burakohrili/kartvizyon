begin;

-- Abonelik durumu yalnız güvenilir ödeme webhook'ları tarafından yazılır.
-- 0016'daki politika kişisel alan sahibinin kendi plan/status değerini
-- değiştirmesine izin veriyordu.
drop policy if exists subscriptions_admin_write on public.workspace_subscriptions;

alter table public.subscription_plans
  drop constraint if exists subscription_plans_distribution_check;
alter table public.subscription_plans
  add constraint subscription_plans_distribution_check
  check (distribution in ('free', 'iap', 'web', 'multi'));
update public.subscription_plans set distribution = 'multi' where id = 'individual';

create table public.billing_product_mappings (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (provider in ('apple', 'google')),
  store_product_id text not null check (char_length(store_product_id) between 2 and 255),
  base_plan_id text,
  plan_id text not null references public.subscription_plans(id),
  billing_period text not null check (billing_period in ('monthly', 'annual')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index billing_product_mapping_identity_idx
  on public.billing_product_mappings(provider, store_product_id, coalesce(base_plan_id, ''));

insert into public.billing_product_mappings
  (provider, store_product_id, base_plan_id, plan_id, billing_period)
values
  ('apple', 'app.kartvizyon.mobile.premium.monthly', null, 'individual', 'monthly'),
  ('apple', 'app.kartvizyon.mobile.premium.annual', null, 'individual', 'annual'),
  ('google', 'premium_individual', 'monthly', 'individual', 'monthly'),
  ('google', 'premium_individual', 'annual', 'individual', 'annual');

create table public.billing_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (provider in ('revenuecat')),
  event_id text not null,
  event_type text not null,
  payload_hash text not null check (payload_hash ~ '^[a-f0-9]{64}$'),
  environment text not null check (environment in ('PRODUCTION', 'SANDBOX')),
  outcome text not null check (outcome in ('processed', 'ignored')),
  occurred_at timestamptz not null,
  processed_at timestamptz not null default now(),
  unique (provider, event_id)
);

create table public.store_purchases (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (provider in ('apple', 'google')),
  user_id uuid not null references public.profiles(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  store_product_id text not null,
  base_plan_id text,
  transaction_id text not null,
  original_transaction_id text not null,
  environment text not null check (environment in ('PRODUCTION', 'SANDBOX')),
  status public.subscription_status not null,
  purchased_at timestamptz,
  expires_at timestamptz,
  auto_renewing boolean not null default true,
  last_event_at timestamptz not null,
  updated_at timestamptz not null default now(),
  unique (provider, original_transaction_id),
  unique (provider, transaction_id)
);
create index store_purchases_workspace_idx on public.store_purchases(workspace_id, updated_at desc);

alter table public.billing_product_mappings enable row level security;
alter table public.billing_events enable row level security;
alter table public.store_purchases enable row level security;

create policy billing_products_authenticated_read on public.billing_product_mappings
  for select to authenticated using (active);
create policy billing_events_no_client_access on public.billing_events
  for all using (false) with check (false);
create policy store_purchases_owner_read on public.store_purchases
  for select to authenticated using (user_id = auth.uid() and public.can_access_workspace(workspace_id));
-- billing_events istemciden okunmaz; yeni tablolarda istemci yazma politikası yoktur.

create or replace function public.apply_store_billing_event(
  event_id_input text,
  event_type_input text,
  payload_hash_input text,
  environment_input text,
  store_provider_input text,
  user_id_input uuid,
  workspace_id_input uuid,
  plan_id_input text,
  store_product_id_input text,
  base_plan_id_input text,
  transaction_id_input text,
  original_transaction_id_input text,
  status_input public.subscription_status,
  purchased_at_input timestamptz,
  expires_at_input timestamptz,
  auto_renewing_input boolean,
  occurred_at_input timestamptz
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  event_inserted integer;
  existing_event_at timestamptz;
begin
  if not exists (
    select 1 from public.workspaces
    where id = workspace_id_input and kind = 'personal'
      and owner_user_id = user_id_input and organization_id is null
  ) then
    raise exception 'Store billing only supports the owner personal workspace';
  end if;

  insert into public.billing_events
    (provider, event_id, event_type, payload_hash, environment, outcome, occurred_at)
  values
    ('revenuecat', event_id_input, event_type_input, payload_hash_input,
     environment_input, 'processed', occurred_at_input)
  on conflict (provider, event_id) do nothing;
  get diagnostics event_inserted = row_count;
  if event_inserted = 0 then return 'duplicate'; end if;

  select last_event_at into existing_event_at
  from public.store_purchases
  where provider = store_provider_input
    and original_transaction_id = original_transaction_id_input
  for update;

  if existing_event_at is not null and existing_event_at > occurred_at_input then
    update public.billing_events set outcome = 'ignored'
    where provider = 'revenuecat' and event_id = event_id_input;
    return 'stale';
  end if;

  insert into public.store_purchases
    (provider, user_id, workspace_id, store_product_id, base_plan_id,
     transaction_id, original_transaction_id, environment, status,
     purchased_at, expires_at, auto_renewing, last_event_at)
  values
    (store_provider_input, user_id_input, workspace_id_input,
     store_product_id_input, base_plan_id_input, transaction_id_input,
     original_transaction_id_input, environment_input, status_input,
     purchased_at_input, expires_at_input, auto_renewing_input, occurred_at_input)
  on conflict (provider, original_transaction_id) do update set
    user_id = excluded.user_id,
    workspace_id = excluded.workspace_id,
    store_product_id = excluded.store_product_id,
    base_plan_id = excluded.base_plan_id,
    transaction_id = excluded.transaction_id,
    environment = excluded.environment,
    status = excluded.status,
    purchased_at = excluded.purchased_at,
    expires_at = excluded.expires_at,
    auto_renewing = excluded.auto_renewing,
    last_event_at = excluded.last_event_at,
    updated_at = now();

  insert into public.workspace_subscriptions
    (workspace_id, organization_id, plan_id, status, seat_quantity, provider,
     provider_customer_id, provider_subscription_id,
     provider_original_transaction_id, current_period_start,
     current_period_end, cancel_at_period_end, trial_ends_at, updated_at)
  values
    (workspace_id_input, null, plan_id_input, status_input, 1, store_provider_input,
     user_id_input::text, transaction_id_input, original_transaction_id_input,
     coalesce(purchased_at_input, now()), coalesce(expires_at_input, now()),
     not auto_renewing_input, null, now())
  on conflict (workspace_id) do update set
    plan_id = excluded.plan_id,
    status = excluded.status,
    seat_quantity = 1,
    provider = excluded.provider,
    provider_customer_id = excluded.provider_customer_id,
    provider_subscription_id = excluded.provider_subscription_id,
    provider_original_transaction_id = excluded.provider_original_transaction_id,
    current_period_start = excluded.current_period_start,
    current_period_end = excluded.current_period_end,
    cancel_at_period_end = excluded.cancel_at_period_end,
    trial_ends_at = null,
    updated_at = now();

  return 'processed';
end;
$$;

revoke all on function public.apply_store_billing_event(text,text,text,text,text,uuid,uuid,text,text,text,text,text,public.subscription_status,timestamptz,timestamptz,boolean,timestamptz) from public, anon, authenticated;
grant execute on function public.apply_store_billing_event(text,text,text,text,text,uuid,uuid,text,text,text,text,text,public.subscription_status,timestamptz,timestamptz,boolean,timestamptz) to service_role;

commit;
