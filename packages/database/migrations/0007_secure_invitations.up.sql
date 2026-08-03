begin;

create or replace function public.create_invitation(target_organization_id uuid, target_email text, target_role public.membership_role, valid_for_days integer default 7)
returns table (invitation_id uuid, invitation_token text)
language plpgsql security definer set search_path = '' as $$
declare
  raw_token text;
  target_workspace_id uuid;
begin
  if auth.uid() is null then raise exception 'Oturum gerekli'; end if;
  if not public.has_organization_role(target_organization_id, array['owner', 'sales_director']::public.membership_role[]) then
    raise exception 'Davet oluşturma yetkiniz yok';
  end if;
  if target_email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' then raise exception 'E-posta geçersiz'; end if;
  if valid_for_days < 1 or valid_for_days > 30 then raise exception 'Davet süresi geçersiz'; end if;

  raw_token := encode(gen_random_bytes(32), 'hex');
  insert into public.invitations (organization_id, email, role, token_hash, invited_by, expires_at)
  values (target_organization_id, lower(trim(target_email)), target_role, encode(digest(raw_token, 'sha256'), 'hex'), auth.uid(), now() + make_interval(days => valid_for_days))
  returning id into invitation_id;

  select id into target_workspace_id from public.workspaces where organization_id = target_organization_id;
  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id, metadata)
  values (target_organization_id, target_workspace_id, auth.uid(), 'invitation.created', 'invitation', invitation_id::text, jsonb_build_object('email', lower(trim(target_email)), 'role', target_role));

  invitation_token := raw_token;
  return next;
end;
$$;

create or replace function public.revoke_invitation(target_invitation_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  target_invitation public.invitations%rowtype;
  target_workspace_id uuid;
begin
  select * into target_invitation from public.invitations where id = target_invitation_id;
  if not found then raise exception 'Davet bulunamadı'; end if;
  if not public.has_organization_role(target_invitation.organization_id, array['owner', 'sales_director']::public.membership_role[]) then
    raise exception 'Davet iptal yetkiniz yok';
  end if;
  update public.invitations set status = 'revoked' where id = target_invitation_id and status = 'pending';
  select id into target_workspace_id from public.workspaces where organization_id = target_invitation.organization_id;
  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id)
  values (target_invitation.organization_id, target_workspace_id, auth.uid(), 'invitation.revoked', 'invitation', target_invitation_id::text);
end;
$$;

revoke all on function public.create_invitation(uuid, text, public.membership_role, integer) from public;
revoke all on function public.revoke_invitation(uuid) from public;
grant execute on function public.create_invitation(uuid, text, public.membership_role, integer) to authenticated;
grant execute on function public.revoke_invitation(uuid) to authenticated;

commit;
