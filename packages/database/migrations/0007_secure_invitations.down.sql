begin;

drop function if exists public.revoke_invitation(uuid);
drop function if exists public.create_invitation(uuid, text, public.membership_role, integer);

commit;
