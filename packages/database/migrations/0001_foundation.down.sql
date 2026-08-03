begin;

drop table if exists public.audit_logs;
drop table if exists public.customer_memory_cards;
drop table if exists public.tasks;
drop table if exists public.visits;
drop table if exists public.contacts;
drop table if exists public.companies;
drop table if exists public.invitations;
drop table if exists public.memberships;
drop table if exists public.workspaces;
drop table if exists public.organizations;
drop table if exists public.profiles;
drop function if exists public.can_access_workspace(uuid);
drop function if exists public.has_organization_role(uuid, public.membership_role[]);
drop function if exists public.is_organization_member(uuid);
drop type if exists public.task_status;
drop type if exists public.invitation_status;
drop type if exists public.record_status;
drop type if exists public.membership_role;
drop type if exists public.workspace_kind;

commit;
