begin;

create table public.report_shares (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  created_by uuid not null references public.profiles(id),
  title text not null check (char_length(title) between 2 and 160),
  token_hash text not null unique,
  filters jsonb not null default '{}'::jsonb,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  last_accessed_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > created_at)
);

create index report_shares_workspace_created_idx
  on public.report_shares(workspace_id, created_at desc);

alter table public.report_shares enable row level security;

create policy report_shares_scope_read on public.report_shares for select using (
  public.can_access_workspace(workspace_id)
);

create or replace function public.create_report_share(
  target_workspace_id uuid,
  raw_token text,
  report_title text,
  report_filters jsonb default '{}'::jsonb,
  valid_for_hours integer default 168
)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  target_organization_id uuid;
  share_id uuid;
begin
  if auth.uid() is null then raise exception 'Oturum gerekli'; end if;
  if not public.can_access_workspace(target_workspace_id) then raise exception 'Çalışma alanına erişiminiz yok'; end if;
  if char_length(trim(report_title)) < 2 or char_length(trim(report_title)) > 160 then raise exception 'Rapor başlığı geçersiz'; end if;
  if valid_for_hours < 1 or valid_for_hours > 720 then raise exception 'Paylaşım süresi geçersiz'; end if;
  if char_length(raw_token) < 32 then raise exception 'Paylaşım tokenı geçersiz'; end if;

  select organization_id into target_organization_id
  from public.workspaces where id = target_workspace_id;

  insert into public.report_shares (
    workspace_id, organization_id, created_by, title, token_hash, filters, expires_at
  ) values (
    target_workspace_id,
    target_organization_id,
    auth.uid(),
    trim(report_title),
    encode(digest(raw_token, 'sha256'), 'hex'),
    coalesce(report_filters, '{}'::jsonb),
    now() + make_interval(hours => valid_for_hours)
  ) returning id into share_id;

  insert into public.audit_logs (
    organization_id, workspace_id, actor_id, action, resource_type, resource_id,
    metadata
  ) values (
    target_organization_id, target_workspace_id, auth.uid(),
    'report.shared', 'report_share', share_id::text,
    jsonb_build_object('expires_in_hours', valid_for_hours)
  );

  return share_id;
end;
$$;

create or replace function public.revoke_report_share(target_share_id uuid)
returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  target_share public.report_shares%rowtype;
begin
  select * into target_share from public.report_shares where id = target_share_id;
  if not found then return false; end if;
  if not public.can_access_workspace(target_share.workspace_id) then raise exception 'Paylaşımı iptal etme yetkiniz yok'; end if;

  update public.report_shares
  set revoked_at = coalesce(revoked_at, now())
  where id = target_share_id;

  insert into public.audit_logs (
    organization_id, workspace_id, actor_id, action, resource_type, resource_id
  ) values (
    target_share.organization_id, target_share.workspace_id, auth.uid(),
    'report.share_revoked', 'report_share', target_share_id::text
  );
  return true;
end;
$$;

create or replace function public.record_report_export(
  target_workspace_id uuid,
  export_format text,
  report_filters jsonb default '{}'::jsonb
)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  target_organization_id uuid;
begin
  if auth.uid() is null or not public.can_access_workspace(target_workspace_id) then
    raise exception 'Rapor dışa aktarma yetkiniz yok';
  end if;
  if export_format not in ('pdf', 'xlsx') then raise exception 'Dışa aktarma biçimi geçersiz'; end if;
  select organization_id into target_organization_id from public.workspaces where id = target_workspace_id;
  insert into public.audit_logs (
    organization_id, workspace_id, actor_id, action, resource_type, metadata
  ) values (
    target_organization_id, target_workspace_id, auth.uid(),
    'report.exported', 'report',
    jsonb_build_object('format', export_format, 'filters', coalesce(report_filters, '{}'::jsonb))
  );
end;
$$;

create or replace function public.get_shared_report(share_token text)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  target_share public.report_shares%rowtype;
  result jsonb;
begin
  select * into target_share
  from public.report_shares
  where token_hash = encode(digest(share_token, 'sha256'), 'hex')
    and revoked_at is null
    and expires_at > now();
  if not found then return null; end if;

  update public.report_shares set last_accessed_at = now() where id = target_share.id;

  select jsonb_build_object(
    'title', target_share.title,
    'expiresAt', target_share.expires_at,
    'filters', target_share.filters,
    'visits', coalesce(jsonb_agg(jsonb_build_object(
      'id', data.id,
      'approvedAt', data.approved_at,
      'companyName', data.company_name,
      'summary', data.ai_summary
    ) order by data.approved_at desc), '[]'::jsonb)
  ) into result
  from (
    select v.id, v.approved_at, c.name as company_name, v.ai_summary
    from public.visits v
    join public.companies c on c.id = v.company_id
    where v.workspace_id = target_share.workspace_id
      and v.status = 'approved'
      and (
        not (target_share.filters ? 'from') or
        v.approved_at >= (target_share.filters ->> 'from')::date
      )
      and (
        not (target_share.filters ? 'to') or
        v.approved_at < ((target_share.filters ->> 'to')::date + interval '1 day')
      )
      and (
        not (target_share.filters ? 'representativeId') or
        v.representative_id = (target_share.filters ->> 'representativeId')::uuid
      )
      and (
        not (target_share.filters ? 'companyId') or
        v.company_id = (target_share.filters ->> 'companyId')::uuid
      )
    order by v.approved_at desc
    limit 1000
  ) data;

  return result;
end;
$$;

revoke all on function public.create_report_share(uuid, text, text, jsonb, integer) from public;
revoke all on function public.revoke_report_share(uuid) from public;
revoke all on function public.record_report_export(uuid, text, jsonb) from public;
revoke all on function public.get_shared_report(text) from public;
grant execute on function public.create_report_share(uuid, text, text, jsonb, integer) to authenticated;
grant execute on function public.revoke_report_share(uuid) to authenticated;
grant execute on function public.record_report_export(uuid, text, jsonb) to authenticated;
grant execute on function public.get_shared_report(text) to anon, authenticated;

commit;
