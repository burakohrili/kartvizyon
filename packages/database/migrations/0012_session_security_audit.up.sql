begin;

create or replace function public.record_session_revocation()
returns void language plpgsql security definer set search_path = '' as $$
declare
  target_workspace_id uuid;
begin
  if auth.uid() is null then raise exception 'Oturum gerekli'; end if;
  select id into target_workspace_id
  from public.workspaces
  where kind = 'personal' and owner_user_id = auth.uid()
  order by created_at asc limit 1;
  if target_workspace_id is null then raise exception 'Çalışma alanı bulunamadı'; end if;
  insert into public.audit_logs (
    workspace_id, actor_id, action, resource_type, resource_id, metadata
  ) values (
    target_workspace_id, auth.uid(), 'session.revoked_all', 'user', auth.uid()::text,
    jsonb_build_object('scope', 'global')
  );
end;
$$;

revoke all on function public.record_session_revocation() from public;
grant execute on function public.record_session_revocation() to authenticated;

commit;
