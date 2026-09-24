begin;

-- Store events are an append/update ledger. The workspace subscription is a
-- projection of every still-valid purchase, never of the last webhook alone.
create or replace function public.reconcile_store_subscription(workspace_id_input uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  purchase_record record;
begin
  select sp.*, bpm.plan_id
    into purchase_record
  from public.store_purchases sp
  join public.billing_product_mappings bpm
    on bpm.provider = sp.provider
   and bpm.store_product_id = sp.store_product_id
   and coalesce(bpm.base_plan_id, '') = coalesce(sp.base_plan_id, '')
   and bpm.active
  where sp.workspace_id = workspace_id_input
    and sp.status in ('active', 'cancelled', 'past_due')
    and sp.expires_at is not null
    and sp.expires_at > now()
  order by
    case sp.environment when 'PRODUCTION' then 0 else 1 end,
    sp.expires_at desc,
    sp.last_event_at desc
  limit 1;

  if found then
    insert into public.workspace_subscriptions
      (workspace_id, organization_id, plan_id, status, seat_quantity, provider,
       provider_customer_id, provider_subscription_id,
       provider_original_transaction_id, current_period_start,
       current_period_end, cancel_at_period_end, trial_ends_at, updated_at)
    values
      (workspace_id_input, null, purchase_record.plan_id,
       purchase_record.status, 1, purchase_record.provider,
       purchase_record.user_id::text, purchase_record.transaction_id,
       purchase_record.original_transaction_id,
       coalesce(purchase_record.purchased_at, now()), purchase_record.expires_at,
       not purchase_record.auto_renewing, null, now())
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
  else
    -- Keep a native-provider marker so a consumed trial cannot reopen.
    update public.workspace_subscriptions
       set plan_id = 'free', status = 'cancelled',
           current_period_end = least(current_period_end, now()),
           cancel_at_period_end = true, trial_ends_at = null, updated_at = now()
     where workspace_id = workspace_id_input
       and provider in ('apple', 'google');
  end if;
end;
$$;

revoke all on function public.reconcile_store_subscription(uuid) from public, anon, authenticated;
grant execute on function public.reconcile_store_subscription(uuid) to service_role;

create or replace function public.transfer_store_billing_ownership(
  event_id_input text,
  payload_hash_input text,
  environment_input text,
  store_provider_input text,
  from_user_id_input uuid,
  from_workspace_id_input uuid,
  to_user_id_input uuid,
  to_workspace_id_input uuid,
  occurred_at_input timestamptz
) returns text
language plpgsql security definer set search_path = '' as $$
declare event_inserted integer;
begin
  if not exists (
    select 1 from public.workspaces
     where id = from_workspace_id_input and kind = 'personal'
       and owner_user_id = from_user_id_input and organization_id is null
  ) or not exists (
    select 1 from public.workspaces
     where id = to_workspace_id_input and kind = 'personal'
       and owner_user_id = to_user_id_input and organization_id is null
  ) then
    raise exception 'Store billing transfer requires personal owner workspaces';
  end if;

  insert into public.billing_events
    (provider, event_id, event_type, payload_hash, environment, outcome, occurred_at)
  values ('revenuecat', event_id_input, 'TRANSFER', payload_hash_input,
          environment_input, 'processed', occurred_at_input)
  on conflict (provider, event_id) do nothing;
  get diagnostics event_inserted = row_count;
  if event_inserted = 0 then return 'duplicate'; end if;

  update public.store_purchases
     set user_id = to_user_id_input,
         workspace_id = to_workspace_id_input,
         updated_at = now()
   where provider = store_provider_input
     and user_id = from_user_id_input
     and workspace_id = from_workspace_id_input
     and environment = environment_input;

  perform public.reconcile_store_subscription(from_workspace_id_input);
  perform public.reconcile_store_subscription(to_workspace_id_input);
  return 'processed';
end;
$$;

revoke all on function public.transfer_store_billing_ownership(text,text,text,text,uuid,uuid,uuid,uuid,timestamptz) from public, anon, authenticated;
grant execute on function public.transfer_store_billing_ownership(text,text,text,text,uuid,uuid,uuid,uuid,timestamptz) to service_role;

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
  previous_workspace_id uuid;
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

  -- A sandbox delivery can coexist in the ledger but must never replace a
  -- production entitlement for the same workspace.
  if environment_input = 'SANDBOX' and exists (
    select 1 from public.store_purchases
     where workspace_id = workspace_id_input
       and environment = 'PRODUCTION'
       and expires_at > now()
  ) then
    update public.billing_events set outcome = 'ignored'
     where provider = 'revenuecat' and event_id = event_id_input;
    return 'environment_ignored';
  end if;

  select last_event_at, workspace_id
    into existing_event_at, previous_workspace_id
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

  if previous_workspace_id is not null
     and previous_workspace_id <> workspace_id_input then
    perform public.reconcile_store_subscription(previous_workspace_id);
  end if;
  perform public.reconcile_store_subscription(workspace_id_input);
  return 'processed';
end;
$$;

revoke all on function public.apply_store_billing_event(text,text,text,text,text,uuid,uuid,text,text,text,text,text,public.subscription_status,timestamptz,timestamptz,boolean,timestamptz) from public, anon, authenticated;
grant execute on function public.apply_store_billing_event(text,text,text,text,text,uuid,uuid,text,text,text,text,text,public.subscription_status,timestamptz,timestamptz,boolean,timestamptz) to service_role;

-- A billing issue or a scheduled pause does not end an already-paid period.
-- Expiry remains authoritative through current_period_end.
create or replace function public.workspace_entitlement(workspace_id_input uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare w public.workspaces%rowtype; s public.workspace_subscriptions%rowtype;
  p public.subscription_plans%rowtype; t public.account_trials%rowtype;
  paid boolean := false; trial boolean := false; period_start timestamptz; seats integer := 1;
begin
  if auth.role() <> 'service_role' and not public.can_access_workspace(workspace_id_input) then raise exception 'Workspace access denied' using errcode = '42501'; end if;
  select * into strict w from public.workspaces where id = workspace_id_input;
  select * into s from public.workspace_subscriptions where workspace_id = w.id;
  select * into t from public.account_trials where user_id = coalesce(w.owner_user_id,
    (select owner_id from public.organizations where id=w.organization_id));
  paid := coalesce(s.plan_id <> 'free' and s.status in ('active','cancelled','past_due') and s.current_period_start <= now() and s.current_period_end > now(), false);
  trial := not paid and coalesce(s.provider is null, true) and coalesce(t.ends_at > now(), false);
  select * into p from public.subscription_plans where id = case when paid then s.plan_id when trial then 'individual' else 'free' end;
  seats := case when paid then greatest(1,s.seat_quantity) else 1 end;
  period_start := case when paid then public.usage_month_start(s.current_period_start, now()) else t.started_at end;
  return jsonb_build_object('planId',p.id,'planName',case when trial then '14 günlük deneme' else p.name end,
    'status',case when trial then 'trialing' when paid then s.status::text else 'read_only' end,
    'readOnly',not (paid or trial),'trialActive',trial,'trialEndsAt',t.ends_at,
    'seatsPurchased',seats,'periodStart',coalesce(period_start,now()),
    'accessEndsAt',case when paid then s.current_period_end when trial then t.ends_at else null end,
    'limits',jsonb_build_object('companies',case when paid or trial then p.max_companies else 0 end,
      'aiMinutes',case when trial then 120 when paid then p.monthly_ai_minutes*seats else 0 end,
      'ocr',case when trial then 60 when paid then p.max_ocr*seats else 0 end,
      'aiSummaries',case when trial then 60 when paid then p.monthly_ai_summaries*seats else 0 end,
      'documentBytes',case when paid or trial then p.monthly_document_bytes else 0 end,'seats',p.seat_limit),
    'topUp',jsonb_build_object('aiMinutes',0,'ocr',0));
end $$;

commit;
