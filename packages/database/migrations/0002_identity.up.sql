begin;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  profile_name text;
begin
  profile_name := coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(new.email, '@', 1));
  insert into public.profiles (id, full_name) values (new.id, profile_name);
  insert into public.workspaces (kind, name, owner_user_id) values ('personal', 'Kişisel Alanım', new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.create_organization(organization_name text, organization_slug text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  new_organization_id uuid;
  new_workspace_id uuid;
begin
  if auth.uid() is null then raise exception 'Oturum gerekli'; end if;
  if char_length(trim(organization_name)) < 2 then raise exception 'Organizasyon adı geçersiz'; end if;

  insert into public.organizations (name, slug, owner_id)
  values (trim(organization_name), lower(trim(organization_slug)), auth.uid())
  returning id into new_organization_id;

  insert into public.workspaces (kind, name, organization_id)
  values ('organization', trim(organization_name), new_organization_id)
  returning id into new_workspace_id;

  insert into public.memberships (organization_id, user_id, role)
  values (new_organization_id, auth.uid(), 'owner');

  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id)
  values (new_organization_id, new_workspace_id, auth.uid(), 'organization.created', 'organization', new_organization_id::text);

  return new_organization_id;
end;
$$;

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

grant execute on function public.create_organization(text, text) to authenticated;
grant execute on function public.accept_invitation(text) to authenticated;

commit;
