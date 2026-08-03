begin;

create or replace function public.audit_visit_status_change()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  audit_action text;
  audit_actor uuid;
begin
  if old.status is not distinct from new.status then return new; end if;
  audit_action := case
    when new.status = 'needs_review' then 'visit.ai_ready'
    when new.status = 'approved' then 'visit.approved'
    when old.status = 'needs_review' and new.status = 'draft' then 'visit.returned_to_draft'
    else null
  end;
  if audit_action is null then return new; end if;
  audit_actor := coalesce(new.approved_by, auth.uid(), new.representative_id);
  insert into public.audit_logs (
    organization_id, workspace_id, actor_id, action, resource_type, resource_id, metadata
  ) values (
    new.organization_id, new.workspace_id, audit_actor, audit_action, 'visit', new.id::text,
    jsonb_build_object('from_status', old.status, 'to_status', new.status, 'ai_schema_version', new.ai_schema_version)
  );
  return new;
end;
$$;

create trigger visit_status_audit
after update of status on public.visits
for each row execute function public.audit_visit_status_change();

revoke all on function public.audit_visit_status_change() from public;

commit;
