begin;
revoke execute on function public.rename_workspace_company(uuid,text) from authenticated;
drop function public.rename_workspace_company(uuid,text);
drop trigger organization_identity_write_guard on public.organizations;
drop trigger workspace_identity_write_guard on public.workspaces;
drop function public.require_identity_subscription();
drop policy organizations_owner_update on public.organizations;
drop policy workspaces_owner_update on public.workspaces;
commit;
