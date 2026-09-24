begin;

drop function if exists public.update_order_draft(uuid, uuid, uuid, date, text, text, jsonb);

create or replace function public.transition_order_draft(target_order_id uuid, target_status public.order_draft_status, rejection_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare target_order public.order_drafts%rowtype;
begin
  select * into target_order from public.order_drafts where id = target_order_id;
  if not found or not public.can_access_workspace(target_order.workspace_id) then raise exception 'Sipariş taslağına erişiminiz yok'; end if;
  if target_status = 'pending_approval' then
    if target_order.created_by <> auth.uid() or target_order.status <> 'draft' then raise exception 'Sipariş onaya gönderilemez'; end if;
    update public.order_drafts set status = target_status, updated_at = now() where id = target_order_id;
  elsif target_status in ('approved', 'rejected') then
    if target_order.organization_id is null or not public.has_organization_role(target_order.organization_id, array['owner', 'sales_director', 'regional_manager']::public.membership_role[]) then raise exception 'Sipariş onay yetkiniz yok'; end if;
    if target_order.status <> 'pending_approval' then raise exception 'Sipariş onay beklemiyor'; end if;
    update public.order_drafts set status = target_status, approved_by = auth.uid(), approved_at = case when target_status = 'approved' then now() else null end, rejected_reason = case when target_status = 'rejected' then rejection_reason else null end, updated_at = now() where id = target_order_id;
  else raise exception 'Geçersiz durum geçişi';
  end if;
  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id, metadata)
  values (target_order.organization_id, target_order.workspace_id, auth.uid(), 'order.' || target_status::text, 'order_draft', target_order_id::text, jsonb_build_object('from', target_order.status, 'to', target_status));
end;
$$;

alter table public.order_drafts drop column rejected_at;

commit;
