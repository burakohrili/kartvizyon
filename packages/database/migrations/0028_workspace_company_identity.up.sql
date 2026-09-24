begin;

create policy workspaces_owner_update on public.workspaces for update to authenticated
using ((kind = 'personal' and owner_user_id = (select auth.uid())) or
  (kind = 'organization' and public.has_organization_role(organization_id, array['owner']::public.membership_role[])))
with check ((kind = 'personal' and owner_user_id = (select auth.uid()) and organization_id is null) or
  (kind = 'organization' and owner_user_id is null and public.has_organization_role(organization_id, array['owner']::public.membership_role[])));

create policy organizations_owner_update on public.organizations for update to authenticated
using (public.has_organization_role(id, array['owner']::public.membership_role[]))
with check (public.has_organization_role(id, array['owner']::public.membership_role[]));

create function public.require_identity_subscription() returns trigger
language plpgsql security definer set search_path = '' as $$
declare target_workspace_id uuid;
begin
  if auth.role() = 'service_role' or auth.uid() is null then return new; end if;
  if tg_table_name = 'workspaces' then
    if old.id is distinct from new.id or old.kind is distinct from new.kind or
      old.owner_user_id is distinct from new.owner_user_id or
      old.organization_id is distinct from new.organization_id or
      old.created_at is distinct from new.created_at then
      raise exception 'Çalışma alanı kimliği değiştirilemez' using errcode = '42501';
    end if;
    target_workspace_id := old.id;
  else
    if old.id is distinct from new.id or old.owner_id is distinct from new.owner_id or
      old.slug is distinct from new.slug or
      old.created_at is distinct from new.created_at or
      old.archived_at is distinct from new.archived_at then
      raise exception 'Organizasyon kimliği değiştirilemez' using errcode = '42501';
    end if;
    select id into target_workspace_id from public.workspaces where organization_id = old.id;
  end if;
  if (public.workspace_entitlement(target_workspace_id)->>'readOnly')::boolean then
    raise exception 'Abonelik gerekli' using errcode = '42501';
  end if;
  return new;
end $$;

create trigger workspace_identity_write_guard before update on public.workspaces
for each row execute function public.require_identity_subscription();
create trigger organization_identity_write_guard before update on public.organizations
for each row execute function public.require_identity_subscription();

create function public.rename_workspace_company(target_workspace_id uuid, company_name text)
returns void language plpgsql security invoker set search_path = '' as $$
declare target public.workspaces%rowtype;
begin
  if char_length(trim(company_name)) < 2 or char_length(trim(company_name)) > 160 then
    raise exception 'Firma adı 2–160 karakter olmalı';
  end if;
  select * into target from public.workspaces where id = target_workspace_id for update;
  if not found then raise exception 'Çalışma alanı bulunamadı' using errcode = '42501'; end if;
  if target.kind = 'organization' then
    update public.organizations set name = trim(company_name) where id = target.organization_id;
    if not found then raise exception 'Organizasyon adı güncellenemedi' using errcode = '42501'; end if;
  end if;
  update public.workspaces set name = trim(company_name) where id = target.id;
  if not found then raise exception 'Firma adı güncellenemedi' using errcode = '42501'; end if;
end $$;
revoke all on function public.rename_workspace_company(uuid,text) from public, anon;
grant execute on function public.rename_workspace_company(uuid,text) to authenticated;

commit;
