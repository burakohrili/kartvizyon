begin;

-- ADR-0009: kartsız deneme, ardından yalnız görüntüleme.
alter table public.subscription_plans add column monthly_ai_summaries integer not null default 125 check (monthly_ai_summaries >= 0);
update public.subscription_plans set monthly_price_try = 449, price_per_seat_try = 449,
  annual_price_try = null, monthly_ai_minutes = 240, max_ocr = 125,
  monthly_ai_summaries = 125,
  features = '["Ayda 125 kartvizit taraması", "Ayda 240 dakika ses işleme", "Ayda 125 AI özeti"]'
where id = 'individual';
-- Güncel bireysel ürün yalnız aylıktır. Eski taslaktaki yıllık mağaza
-- kimlikleri yanlışlıkla oluşturulsa bile entitlement açmamalıdır.
do $$ begin
  if to_regclass('public.billing_product_mappings') is not null then
    update public.billing_product_mappings set active = false where billing_period = 'annual';
  end if;
end $$;
update public.subscription_plans set name = 'Yalnız görüntüleme', monthly_ai_minutes = 0,
  max_ocr = 0, monthly_ai_summaries = 0, max_companies = 0 where id = 'free';
update public.ai_topup_packages set active = false;

create table public.account_trials (
  user_id uuid primary key references auth.users(id) on delete cascade,
  started_at timestamptz not null,
  ends_at timestamptz not null,
  check (ends_at = started_at + interval '14 days')
);
alter table public.account_trials enable row level security;
create policy account_trial_read on public.account_trials for select to authenticated using (user_id = auth.uid());

-- Mevcut hesaplara ikinci deneme verilmez; önceki başlangıç korunur.
insert into public.account_trials (user_id, started_at, ends_at)
select u.id, coalesce(min(s.trial_ends_at - interval '14 days'), min(w.created_at), u.last_sign_in_at),
  coalesce(min(s.trial_ends_at - interval '14 days'), min(w.created_at), u.last_sign_in_at) + interval '14 days'
from auth.users u left join public.workspaces w on w.owner_user_id = u.id
left join public.workspace_subscriptions s on s.workspace_id = w.id
where u.email_confirmed_at is not null and u.last_sign_in_at is not null group by u.id;

create function public.start_account_trial() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.email_confirmed_at is not null and new.last_sign_in_at is not null then
    insert into public.account_trials values (new.id, now(), now() + interval '14 days') on conflict do nothing;
  end if;
  return new;
end $$;
create trigger start_account_trial after insert or update of last_sign_in_at, email_confirmed_at on auth.users
for each row execute function public.start_account_trial();

-- SQL ay aritmetiği ay sonunu korur; yıllık tahsilat aylık kotayı değiştirmez.
create function public.usage_month_start(anchor timestamptz, at_time timestamptz) returns timestamptz
language plpgsql immutable set search_path = '' as $$
declare n integer; candidate timestamptz;
begin
  n := greatest(0, (extract(year from at_time at time zone 'UTC')::integer - extract(year from anchor at time zone 'UTC')::integer) * 12
    + extract(month from at_time at time zone 'UTC')::integer - extract(month from anchor at time zone 'UTC')::integer);
  candidate := ((anchor at time zone 'UTC') + make_interval(months => n)) at time zone 'UTC';
  if candidate > at_time then candidate := ((anchor at time zone 'UTC') + make_interval(months => greatest(0,n-1))) at time zone 'UTC'; end if;
  return candidate;
end $$;

create function public.workspace_entitlement(workspace_id_input uuid) returns jsonb
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
  paid := coalesce(s.plan_id <> 'free' and s.status in ('active','cancelled') and s.current_period_start <= now() and s.current_period_end > now(), false);
  -- Satın alma gerçekleşmişse eski deneme bir daha açılmaz.
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
revoke all on function public.workspace_entitlement(uuid) from public, anon;
grant execute on function public.workspace_entitlement(uuid) to authenticated, service_role;

-- Doğrudan Supabase yazmaları da API kontrolünü atlayamaz. Okuma ve gizlilik
-- talepleri ayrı kalır; service_role bakım/silme/ödeme işlemleri engellenmez.
create function public.require_workspace_subscription() returns trigger
language plpgsql security definer set search_path = '' as $$
declare workspace uuid;
begin
  if auth.role() = 'service_role' or auth.uid() is null then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;
  workspace := case when tg_op = 'DELETE' then old.workspace_id else new.workspace_id end;
  if tg_op = 'UPDATE' and old.workspace_id is distinct from new.workspace_id then
    if (public.workspace_entitlement(old.workspace_id)->>'readOnly')::boolean then raise exception 'Abonelik gerekli' using errcode='42501'; end if;
  end if;
  if (public.workspace_entitlement(workspace)->>'readOnly')::boolean then
    raise exception 'Abonelik gerekli. Mevcut kayıtları görüntüleyebilir, dışa aktarabilir veya hesabınızı silebilirsiniz.' using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then return old; else return new; end if;
end $$;
do $$ declare tab text; begin
  foreach tab in array array['companies','contacts','visits','tasks','customer_memory_cards','import_jobs',
    'geofence_events','visit_audio_assets','visit_transcripts','ai_jobs','debrief_submissions','report_shares',
    'opportunities','products','price_lists','order_drafts','activity_comments','documents','form_templates','form_submissions',
    'api_credentials','webhook_endpoints','regions','teams'] loop
    execute format('create trigger subscription_write_guard before insert or update or delete on public.%I for each row execute function public.require_workspace_subscription()',tab);
  end loop;
end $$;

-- AI rezervasyonları tek kilit altında sayılır. İstemci tüketimi değiştiremez.
create table public.ai_quota_operations (
  id uuid primary key,
  workspace_id uuid references public.workspaces(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  trial_owner_id uuid references auth.users(id) on delete cascade,
  request_key text not null,
  period_start timestamptz not null,
  ocr integer not null default 0 check (ocr >= 0),
  audio_seconds integer not null default 0 check (audio_seconds >= 0),
  summaries integer not null default 0 check (summaries >= 0),
  status text not null check (status in ('reserved','completed','failed')),
  response jsonb,
  created_at timestamptz not null default now(),
  unique(user_id, request_key)
);
alter table public.ai_quota_operations enable row level security;
create policy ai_quota_no_client_access on public.ai_quota_operations for all to authenticated using (false) with check (false);
create index ai_quota_period_idx on public.ai_quota_operations(workspace_id,period_start);

create function public.reserve_ai_quota(workspace_id_input uuid, user_id_input uuid, request_key_input text,
  ocr_input integer, audio_seconds_input integer, summaries_input integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare e jsonb; used_ocr bigint; used_audio bigint; used_summaries bigint; op public.ai_quota_operations%rowtype; period timestamptz; trial_owner uuid;
begin
  if ocr_input < 0 or audio_seconds_input < 0 or summaries_input < 0 then raise exception 'Invalid quota amount'; end if;
  select coalesce(w.owner_user_id,o.owner_id) into trial_owner from public.workspaces w left join public.organizations o on o.id=w.organization_id where w.id=workspace_id_input;
  perform pg_advisory_xact_lock(hashtextextended(trial_owner::text,1));
  perform pg_advisory_xact_lock(hashtextextended(workspace_id_input::text,0));
  select * into op from public.ai_quota_operations where user_id=user_id_input and request_key=request_key_input;
  if found and op.workspace_id <> workspace_id_input then raise exception 'Operation workspace mismatch'; end if;
  if op.status = 'completed' then return jsonb_build_object('id',op.id,'response',op.response,'completed',true); end if;
  if op.status = 'reserved' then return jsonb_build_object('error','İşlem hâlen sürüyor.','code','operation_pending'); end if;
  e := public.workspace_entitlement(workspace_id_input);
  if (e->>'readOnly')::boolean then return jsonb_build_object('error','Devam etmek için abonelik başlatın.','code','subscription_required'); end if;
  period := (e->>'periodStart')::timestamptz;
  select coalesce(sum(ocr),0),coalesce(sum(audio_seconds),0),coalesce(sum(summaries),0)
    into used_ocr,used_audio,used_summaries from public.ai_quota_operations
    where (case when (e->>'trialActive')::boolean then trial_owner_id=trial_owner else workspace_id=workspace_id_input and trial_owner_id is null end) and period_start=period and status in ('reserved','completed');
  if used_ocr+ocr_input > (e->'limits'->>'ocr')::integer
    or used_audio+audio_seconds_input > (e->'limits'->>'aiMinutes')::integer*60
    or used_summaries+summaries_input > (e->'limits'->>'aiSummaries')::integer then
    return jsonb_build_object('error','Bu dönemki kullanım hakkınız yeterli değil. Denemedeyseniz abonelik başlatabilirsiniz.','code','quota_exceeded');
  end if;
  insert into public.ai_quota_operations(id,workspace_id,user_id,trial_owner_id,request_key,period_start,ocr,audio_seconds,summaries,status)
    values(gen_random_uuid(),workspace_id_input,user_id_input,case when (e->>'trialActive')::boolean then trial_owner else null end,request_key_input,period,ocr_input,audio_seconds_input,summaries_input,'reserved')
    on conflict(user_id,request_key) do update set period_start=excluded.period_start,trial_owner_id=excluded.trial_owner_id,ocr=excluded.ocr,
      audio_seconds=excluded.audio_seconds,summaries=excluded.summaries,status='reserved',created_at=now()
    returning * into op;
  return jsonb_build_object('id',op.id,'completed',false);
end $$;
revoke all on function public.reserve_ai_quota(uuid,uuid,text,integer,integer,integer) from public,anon,authenticated;
grant execute on function public.reserve_ai_quota(uuid,uuid,text,integer,integer,integer) to service_role;

create function public.workspace_usage(workspace_id_input uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare e jsonb; result jsonb; trial_owner uuid;
begin
  e := public.workspace_entitlement(workspace_id_input);
  select coalesce(w.owner_user_id,o.owner_id) into trial_owner from public.workspaces w left join public.organizations o on o.id=w.organization_id where w.id=workspace_id_input;
  select jsonb_build_object('ocr',coalesce(sum(ocr),0),'audio_seconds',coalesce(sum(audio_seconds),0),'ai_summary',coalesce(sum(summaries),0))
    into result from public.ai_quota_operations where (case when (e->>'trialActive')::boolean then trial_owner_id=trial_owner else workspace_id=workspace_id_input and trial_owner_id is null end)
    and period_start=(e->>'periodStart')::timestamptz and status in ('reserved','completed');
  return result;
end $$;
revoke all on function public.workspace_usage(uuid) from public,anon;
grant execute on function public.workspace_usage(uuid) to authenticated,service_role;

revoke all on function public.start_account_trial() from public,anon,authenticated;
revoke all on function public.require_workspace_subscription() from public,anon,authenticated;
grant select on public.account_trials to authenticated;
grant all on public.account_trials, public.ai_quota_operations to service_role;

-- Storage doğrudan yüklemeleri de üyelik gerektirir; okuma/silme korunur.
create function public.has_writable_workspace() returns boolean
language sql security definer set search_path = '' as $$
  select exists(select 1 from public.workspaces w where public.can_access_workspace(w.id)
    and not (public.workspace_entitlement(w.id)->>'readOnly')::boolean);
$$;
revoke all on function public.has_writable_workspace() from public,anon;
grant execute on function public.has_writable_workspace() to authenticated;
create policy subscription_storage_insert on storage.objects as restrictive for insert to authenticated
  with check (bucket_id not in ('visit-audio','document-quarantine') or public.has_writable_workspace());
create policy subscription_storage_update on storage.objects as restrictive for update to authenticated
  using (bucket_id not in ('visit-audio','document-quarantine') or public.has_writable_workspace())
  with check (bucket_id not in ('visit-audio','document-quarantine') or public.has_writable_workspace());
commit;
