begin;

create or replace function public.enforce_tenant_relation_integrity_2()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  workspace_organization uuid;
begin
  select organization_id into workspace_organization
  from public.workspaces where id = new.workspace_id;
  if not found or workspace_organization is distinct from new.organization_id then
    raise exception 'Workspace organization mismatch' using errcode = '23514';
  end if;

  if tg_table_name = 'documents' then
    if new.company_id is not null and not exists (
      select 1 from public.companies c where c.id = new.company_id
        and c.workspace_id = new.workspace_id
        and c.organization_id is not distinct from new.organization_id
    ) then raise exception 'Document company scope mismatch' using errcode = '23514'; end if;
    if new.visit_id is not null and not exists (
      select 1 from public.visits v where v.id = new.visit_id
        and v.workspace_id = new.workspace_id
        and v.organization_id is not distinct from new.organization_id
    ) then raise exception 'Document visit scope mismatch' using errcode = '23514'; end if;
    if new.order_draft_id is not null and not exists (
      select 1 from public.order_drafts o where o.id = new.order_draft_id
        and o.workspace_id = new.workspace_id
        and o.organization_id is not distinct from new.organization_id
    ) then raise exception 'Document order scope mismatch' using errcode = '23514'; end if;
  elsif tg_table_name = 'form_submissions' then
    if not exists (
      select 1 from public.form_templates t where t.id = new.template_id
        and t.workspace_id = new.workspace_id
        and t.organization_id is not distinct from new.organization_id
    ) then raise exception 'Form template scope mismatch' using errcode = '23514'; end if;
    if new.company_id is not null and not exists (
      select 1 from public.companies c where c.id = new.company_id
        and c.workspace_id = new.workspace_id
        and c.organization_id is not distinct from new.organization_id
    ) then raise exception 'Form company scope mismatch' using errcode = '23514'; end if;
    if new.visit_id is not null and not exists (
      select 1 from public.visits v where v.id = new.visit_id
        and v.workspace_id = new.workspace_id
        and v.organization_id is not distinct from new.organization_id
    ) then raise exception 'Form visit scope mismatch' using errcode = '23514'; end if;
  elsif tg_table_name = 'opportunities' then
    if not exists (
      select 1 from public.companies c where c.id = new.company_id
        and c.workspace_id = new.workspace_id
        and c.organization_id is not distinct from new.organization_id
    ) then raise exception 'Opportunity company scope mismatch' using errcode = '23514'; end if;
    if new.assigned_to is not null and not exists (
      select 1 from public.workspaces w where w.id = new.workspace_id and (
        (w.kind = 'personal' and w.owner_user_id = new.assigned_to) or
        (w.kind = 'organization' and exists (
          select 1 from public.memberships m where m.organization_id = w.organization_id
            and m.user_id = new.assigned_to and m.revoked_at is null
        ))
      )
    ) then raise exception 'Opportunity owner scope mismatch' using errcode = '23514'; end if;
  elsif tg_table_name = 'notifications' then
    if not exists (
      select 1 from public.workspaces w where w.id = new.workspace_id and (
        (w.kind = 'personal' and w.owner_user_id = new.user_id) or
        (w.kind = 'organization' and exists (
          select 1 from public.memberships m where m.organization_id = w.organization_id
            and m.user_id = new.user_id and m.revoked_at is null
        ))
      )
    ) then raise exception 'Notification recipient scope mismatch' using errcode = '23514'; end if;
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_tenant_relation_integrity_2() from public, anon, authenticated;

create trigger documents_relation_integrity_2
before insert or update on public.documents
for each row execute function public.enforce_tenant_relation_integrity_2();
create trigger form_submissions_relation_integrity_2
before insert or update on public.form_submissions
for each row execute function public.enforce_tenant_relation_integrity_2();
create trigger opportunities_relation_integrity_2
before insert or update on public.opportunities
for each row execute function public.enforce_tenant_relation_integrity_2();
create trigger notifications_relation_integrity_2
before insert or update on public.notifications
for each row execute function public.enforce_tenant_relation_integrity_2();

commit;
