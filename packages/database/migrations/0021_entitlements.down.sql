begin;

-- Koltuk kontrolü olmayan 0002_identity sürümüne geri dönülür.
create or replace function public.accept_invitation(invitation_token text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  target_invitation public.invitations%rowtype;
  target_workspace_id uuid;
  signed_in_email text;
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

drop policy if exists topups_admin_no_client_write on public.workspace_ai_topups;
drop policy if exists topups_scope_read on public.workspace_ai_topups;
drop policy if exists topup_packages_authenticated_read on public.ai_topup_packages;
drop table if exists public.workspace_ai_topups;
drop table if exists public.ai_topup_packages;

alter table public.usage_records drop constraint if exists usage_records_metric_check;
alter table public.usage_records add constraint usage_records_metric_check
  check (metric in ('audio_seconds', 'input_tokens', 'output_tokens', 'storage_bytes'));

alter table public.workspace_subscriptions drop column if exists provider_original_transaction_id;
alter table public.workspace_subscriptions drop column if exists trial_ends_at;

-- ADR-0005 öncesi plan tablosuna dönüş. Bu planlara bağlı abonelik varsa önce
-- starter/growth'a taşınmalıdır; aksi halde FK kısıtı rollback'i durdurur.
delete from public.subscription_plans where id in ('free', 'individual', 'team');

update public.subscription_plans set
  name = 'Kurumsal',
  monthly_price_try = 0,
  seat_limit = 500,
  monthly_ai_minutes = 10000,
  monthly_document_bytes = 107374182400,
  features = '["Özel limitler", "SLA", "Gelişmiş güvenlik"]',
  active = true
where id = 'enterprise';

update public.subscription_plans set active = true where id in ('starter', 'growth');

alter table public.subscription_plans drop column if exists distribution;
alter table public.subscription_plans drop column if exists min_seats;
alter table public.subscription_plans drop column if exists annual_price_try;
alter table public.subscription_plans drop column if exists price_per_seat_try;
alter table public.subscription_plans drop column if exists max_ocr;
alter table public.subscription_plans drop column if exists max_companies;

commit;
