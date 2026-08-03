begin;

revoke execute on function public.accept_invitation(text) from authenticated;
revoke execute on function public.create_organization(text, text) from authenticated;
drop function if exists public.accept_invitation(text);
drop function if exists public.create_organization(text, text);
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

commit;
