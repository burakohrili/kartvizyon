begin;

drop policy if exists contacts_scope_all on public.contacts;

create policy contacts_scope_all on public.contacts
for all
using (
  public.can_access_workspace(workspace_id)
  and exists (
    select 1 from public.companies c
    where c.id = company_id
      and c.workspace_id = contacts.workspace_id
      and c.organization_id is not distinct from contacts.organization_id
  )
)
with check (
  public.can_access_workspace(workspace_id)
  and created_by = auth.uid()
  and exists (
    select 1 from public.companies c
    where c.id = company_id
      and c.workspace_id = contacts.workspace_id
      and c.organization_id is not distinct from contacts.organization_id
  )
);

commit;
