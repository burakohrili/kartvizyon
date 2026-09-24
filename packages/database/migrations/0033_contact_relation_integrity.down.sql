begin;

drop policy if exists contacts_scope_all on public.contacts;

create policy contacts_scope_all on public.contacts
for all
using (public.can_access_workspace(workspace_id))
with check (public.can_access_workspace(workspace_id));

commit;
