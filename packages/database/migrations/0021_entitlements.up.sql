begin;

-- ADR-0005: plan limitleri koltuk başına tanımlanır, "sınırsız" null ile ifade edilir.
alter table public.subscription_plans add column if not exists max_companies integer
  check (max_companies is null or max_companies >= 0);
alter table public.subscription_plans add column if not exists max_ocr integer
  check (max_ocr is null or max_ocr >= 0);
alter table public.subscription_plans add column if not exists price_per_seat_try numeric(12,2)
  check (price_per_seat_try is null or price_per_seat_try >= 0);
alter table public.subscription_plans add column if not exists annual_price_try numeric(12,2)
  check (annual_price_try is null or annual_price_try >= 0);
alter table public.subscription_plans add column if not exists min_seats integer not null default 1
  check (min_seats > 0);
alter table public.subscription_plans add column if not exists distribution text not null default 'web'
  check (distribution in ('free', 'iap', 'web'));

-- monthly_ai_minutes ve max_ocr artık koltuk başına değerdir; havuzlanmış kota
-- entitlements.ts içinde seat_quantity ile çarpılarak hesaplanır.
comment on column public.subscription_plans.monthly_ai_minutes is
  'Koltuk başına aylık AI dakikası. Havuz = bu değer * seat_quantity.';
comment on column public.subscription_plans.max_ocr is
  'Koltuk başına aylık OCR adedi. null = sınırsız.';
comment on column public.subscription_plans.max_companies is
  'Çalışma alanı başına müşteri (companies) üst sınırı. null = sınırsız.';

alter table public.workspace_subscriptions add column if not exists trial_ends_at timestamptz;
alter table public.workspace_subscriptions add column if not exists provider_original_transaction_id text;

-- OCR tüketimi de ölçülür; kota bu metrikten hesaplanır.
alter table public.usage_records drop constraint if exists usage_records_metric_check;
alter table public.usage_records add constraint usage_records_metric_check
  check (metric in ('audio_seconds', 'input_tokens', 'output_tokens', 'storage_bytes', 'ocr'));

-- Eski sabit fiyatlı planlar kapatılır; satırlar mevcut FK referansları için korunur.
update public.subscription_plans set active = false where id in ('starter', 'growth');

insert into public.subscription_plans
  (id, name, monthly_price_try, seat_limit, monthly_ai_minutes, monthly_document_bytes,
   features, active, max_companies, max_ocr, price_per_seat_try, annual_price_try,
   min_seats, distribution)
values
  ('free', 'Ücretsiz', 0, 1, 10, 268435456,
   '["5 müşteri kaydı", "Ayda 10 AI dakikası", "Çevrimdışı ziyaret ve görev"]',
   true, 5, 5, 0, 0, 1, 'free'),
  ('individual', 'Bireysel', 349, 1, 120, 5368709120,
   '["Sınırsız müşteri ve ziyaret", "Ayda 120 AI dakikası", "60 kartvizit taraması", "Kişisel takip ve hatırlatmalar"]',
   true, null, 60, 349, 3490, 1, 'web'),
  ('team', 'Ekip', 279, 50, 150, 21474836480,
   '["Bireysel plandaki her şey", "Rol bazlı yetkilendirme ve ekip davetleri", "Fırsat, sipariş taslağı ve ürün listesi", "Yönetici raporları ve paylaşılabilir bağlantılar"]',
   true, null, 80, 279, 2790, 3, 'web')
on conflict (id) do update set
  name = excluded.name,
  monthly_price_try = excluded.monthly_price_try,
  seat_limit = excluded.seat_limit,
  monthly_ai_minutes = excluded.monthly_ai_minutes,
  monthly_document_bytes = excluded.monthly_document_bytes,
  features = excluded.features,
  active = excluded.active,
  max_companies = excluded.max_companies,
  max_ocr = excluded.max_ocr,
  price_per_seat_try = excluded.price_per_seat_try,
  annual_price_try = excluded.annual_price_try,
  min_seats = excluded.min_seats,
  distribution = excluded.distribution;

update public.subscription_plans set
  name = 'Kurumsal',
  monthly_price_try = 449,
  seat_limit = 500,
  monthly_ai_minutes = 250,
  monthly_document_bytes = 107374182400,
  features = '["Ekip plandaki her şey", "Bölge/takım yönetimi ve entegrasyon webhookları", "Genişletilmiş audit log ve veri saklama", "Öncelikli destek ve kurulum danışmanlığı"]',
  active = true,
  max_companies = null,
  max_ocr = null,
  price_per_seat_try = 449,
  annual_price_try = null,
  min_seats = 10,
  distribution = 'web'
where id = 'enterprise';

-- ADR-0005 ek AI paketleri. Katalog; satın alma akışı iyzico bağlanınca eklenir.
create table public.ai_topup_packages (
  id text primary key,
  name text not null,
  price_try numeric(12,2) not null check (price_try >= 0),
  ai_minutes integer not null check (ai_minutes >= 0),
  ocr_count integer not null check (ocr_count >= 0),
  active boolean not null default true
);

insert into public.ai_topup_packages values
  ('ai_100', 'AI 100', 149, 100, 50, true),
  ('ai_300', 'AI 300', 349, 300, 150, true),
  ('ai_1000', 'AI 1000', 899, 1000, 500, true);

-- Satın alınmış paketler süresizdir; aylık kota tükendikten sonra tüketilir.
create table public.workspace_ai_topups (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  package_id text not null references public.ai_topup_packages(id),
  ai_minutes_granted integer not null check (ai_minutes_granted >= 0),
  ai_minutes_used integer not null default 0 check (ai_minutes_used >= 0),
  ocr_granted integer not null check (ocr_granted >= 0),
  ocr_used integer not null default 0 check (ocr_used >= 0),
  provider text,
  provider_reference text,
  purchased_at timestamptz not null default now(),
  constraint topup_minutes_not_overdrawn check (ai_minutes_used <= ai_minutes_granted),
  constraint topup_ocr_not_overdrawn check (ocr_used <= ocr_granted)
);

create index workspace_ai_topups_workspace_idx
  on public.workspace_ai_topups(workspace_id, purchased_at);
create unique index workspace_ai_topups_provider_reference_idx
  on public.workspace_ai_topups(provider, provider_reference)
  where provider_reference is not null;

alter table public.ai_topup_packages enable row level security;
alter table public.workspace_ai_topups enable row level security;

create policy topup_packages_authenticated_read on public.ai_topup_packages
  for select to authenticated using (active);
create policy topups_scope_read on public.workspace_ai_topups
  for select using (public.can_access_workspace(workspace_id));
-- Satın alma yalnız sunucu tarafındaki ödeme webhook'u (service role) tarafından
-- yazılır; istemci hiçbir koşulda kendine kredi tanımlayamaz.
create policy topups_admin_no_client_write on public.workspace_ai_topups
  for all using (false) with check (false);

-- Deneme süresi: mevcut trialing kayıtlar için 14 günlük pencere geriye dönük atanır.
update public.workspace_subscriptions
set trial_ends_at = coalesce(trial_ends_at, created_at + interval '14 days')
where status = 'trialing';

-- Koltuk limiti veritabanında uygulanır. accept_invitation `security definer`
-- olduğu ve anon anahtarla doğrudan RPC olarak çağrılabildiği için API katmanında
-- yapılan bir kontrol atlatılabilirdi.
--
-- Abonelik satırı olmayan organizasyonlar bilinçli olarak muaftır: ödeme akışı
-- bağlanana kadar (ADR-0003/0005) hiçbir organizasyonun koltuk satın alma yolu
-- yok ve mevcut ekipler davet edememezlik durumuna düşürülmez.
create or replace function public.accept_invitation(invitation_token text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  target_invitation public.invitations%rowtype;
  target_workspace_id uuid;
  signed_in_email text;
  seat_allowance integer;
  seats_in_use integer;
  already_member boolean;
begin
  if auth.uid() is null then raise exception 'Oturum gerekli'; end if;
  signed_in_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  select * into target_invitation
  from public.invitations
  where token_hash = encode(digest(invitation_token, 'sha256'), 'hex')
    and status = 'pending'
    and expires_at > now()
  for update;

  if not found then raise exception 'Davet geçersiz veya süresi dolmuş'; end if;
  if lower(target_invitation.email::text) <> signed_in_email then raise exception 'Davet farklı bir e-posta adresine ait'; end if;

  select exists (
    select 1 from public.memberships
    where organization_id = target_invitation.organization_id
      and user_id = auth.uid()
      and revoked_at is null
  ) into already_member;

  if not already_member then
    select least(ws.seat_quantity, sp.seat_limit) into seat_allowance
    from public.workspaces w
    join public.workspace_subscriptions ws on ws.workspace_id = w.id
    join public.subscription_plans sp on sp.id = ws.plan_id
    where w.organization_id = target_invitation.organization_id
    limit 1;

    if seat_allowance is not null then
      select count(*) into seats_in_use
      from public.memberships
      where organization_id = target_invitation.organization_id
        and revoked_at is null;

      if seats_in_use >= seat_allowance then
        raise exception 'Koltuk sayısı doldu; yöneticiniz koltuk eklemeden yeni üye katılamaz';
      end if;
    end if;
  end if;

  insert into public.memberships (organization_id, user_id, role)
  values (target_invitation.organization_id, auth.uid(), target_invitation.role)
  on conflict (organization_id, user_id) do update set role = excluded.role, revoked_at = null;

  update public.invitations
  set status = 'accepted', accepted_by = auth.uid(), accepted_at = now()
  where id = target_invitation.id;

  select id into target_workspace_id from public.workspaces where organization_id = target_invitation.organization_id;
  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id)
  values (target_invitation.organization_id, target_workspace_id, auth.uid(), 'invitation.accepted', 'invitation', target_invitation.id::text);

  return target_invitation.organization_id;
end;
$$;

commit;
