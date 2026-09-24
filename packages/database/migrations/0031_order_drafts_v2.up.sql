begin;

alter table public.order_drafts
  add column rejected_at timestamptz;

create or replace function public.transition_order_draft(target_order_id uuid, target_status public.order_draft_status, rejection_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare
  target_order public.order_drafts%rowtype;
begin
  select * into target_order from public.order_drafts where id = target_order_id for update;
  if not found or not public.can_access_workspace(target_order.workspace_id) then raise exception 'Sipariş taslağına erişiminiz yok'; end if;

  if target_status = 'draft' then
    if target_order.created_by <> auth.uid() or target_order.status <> 'rejected' then raise exception 'Sipariş taslağı düzenlemeye açılamaz'; end if;
    update public.order_drafts set status = 'draft', approved_by = null, approved_at = null,
      rejected_reason = null, rejected_at = null, updated_at = now() where id = target_order_id;
  elsif target_status = 'pending_approval' then
    if target_order.created_by <> auth.uid() or target_order.status <> 'draft' then raise exception 'Sipariş onaya gönderilemez'; end if;
    update public.order_drafts set status = target_status, updated_at = now() where id = target_order_id;
  elsif target_status in ('approved', 'rejected') then
    if target_order.organization_id is null or not public.has_organization_role(target_order.organization_id, array['owner', 'sales_director', 'regional_manager']::public.membership_role[]) then raise exception 'Sipariş onay yetkiniz yok'; end if;
    if target_order.status <> 'pending_approval' then raise exception 'Sipariş onay beklemiyor'; end if;
    if target_status = 'rejected' and char_length(trim(coalesce(rejection_reason, ''))) < 2 then raise exception 'Red nedeni gereklidir'; end if;
    update public.order_drafts set status = target_status, approved_by = auth.uid(),
      approved_at = case when target_status = 'approved' then now() else null end,
      rejected_reason = case when target_status = 'rejected' then trim(rejection_reason) else null end,
      rejected_at = case when target_status = 'rejected' then now() else null end,
      updated_at = now() where id = target_order_id;
  else
    raise exception 'Geçersiz durum geçişi';
  end if;

  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id, metadata)
  values (target_order.organization_id, target_order.workspace_id, auth.uid(), 'order.' || target_status::text,
    'order_draft', target_order_id::text,
    jsonb_strip_nulls(jsonb_build_object('from', target_order.status, 'to', target_status,
      'rejectionReason', case when target_status = 'rejected' then trim(rejection_reason) else null end)));
end;
$$;

create or replace function public.update_order_draft(
  target_order_id uuid,
  target_company_id uuid,
  target_opportunity_id uuid,
  target_delivery_date date,
  target_notes text,
  target_currency text,
  target_items jsonb
) returns void language plpgsql security definer set search_path = '' as $$
declare
  target_order public.order_drafts%rowtype;
  item jsonb;
  product public.products%rowtype;
  item_count integer;
  quantity numeric;
  unit_price numeric;
  discount_percent numeric;
  net numeric;
begin
  select * into target_order from public.order_drafts where id = target_order_id for update;
  if not found or not public.can_access_workspace(target_order.workspace_id) then raise exception 'Sipariş taslağına erişiminiz yok'; end if;
  if target_order.created_by <> auth.uid() or target_order.status <> 'draft' then raise exception 'Yalnız taslak durumundaki sipariş düzenlenebilir'; end if;
  if target_currency not in ('TRY', 'USD', 'EUR') then raise exception 'Para birimi desteklenmiyor'; end if;
  if target_notes is not null and char_length(target_notes) > 2000 then raise exception 'Not çok uzun'; end if;

  perform 1 from public.companies where id = target_company_id and workspace_id = target_order.workspace_id and archived_at is null;
  if not found then raise exception 'Müşteri çalışma alanında bulunamadı veya arşivlenmiş'; end if;
  if target_opportunity_id is not null then
    perform 1 from public.opportunities where id = target_opportunity_id and workspace_id = target_order.workspace_id and company_id = target_company_id;
    if not found then raise exception 'Fırsat müşteri veya çalışma alanıyla uyuşmuyor'; end if;
  end if;

  item_count := jsonb_array_length(coalesce(target_items, '[]'::jsonb));
  if item_count < 1 or item_count > 200 then raise exception 'Sipariş en az bir, en fazla 200 kalem içermelidir'; end if;

  update public.order_drafts set company_id = target_company_id, opportunity_id = target_opportunity_id,
    delivery_date = target_delivery_date, notes = nullif(trim(target_notes), ''), currency = target_currency,
    updated_at = now() where id = target_order_id;
  delete from public.order_draft_items where order_draft_id = target_order_id;

  for item in select value from jsonb_array_elements(target_items)
  loop
    select * into product from public.products
      where id = (item->>'productId')::uuid and workspace_id = target_order.workspace_id and active = true;
    if not found then raise exception 'Ürün çalışma alanında bulunamadı veya aktif değil'; end if;
    if product.currency <> target_currency then raise exception 'Ürün para birimi siparişle uyuşmuyor'; end if;
    quantity := (item->>'quantity')::numeric;
    unit_price := (item->>'unitPrice')::numeric;
    discount_percent := coalesce((item->>'discountPercent')::numeric, 0);
    if quantity <= 0 or unit_price < 0 or discount_percent < 0 or discount_percent > 100 then raise exception 'Sipariş kalemi değerleri geçersiz'; end if;
    net := quantity * unit_price * (1 - discount_percent / 100);
    insert into public.order_draft_items (order_draft_id, product_id, quantity, unit_price, discount_percent, tax_rate, line_total)
    values (target_order_id, product.id, quantity, unit_price, discount_percent, product.tax_rate,
      round(net * (1 + product.tax_rate / 100), 2));
  end loop;

  perform public.recalculate_order_draft(target_order_id);
  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id, metadata)
  values (target_order.organization_id, target_order.workspace_id, auth.uid(), 'order.updated', 'order_draft', target_order_id::text,
    jsonb_build_object('itemCount', item_count));
end;
$$;

revoke all on function public.update_order_draft(uuid, uuid, uuid, date, text, text, jsonb) from public;
grant execute on function public.update_order_draft(uuid, uuid, uuid, date, text, text, jsonb) to authenticated;

commit;
