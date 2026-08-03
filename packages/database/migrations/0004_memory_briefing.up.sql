begin;

create or replace function public.refresh_customer_memory_card(target_company_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  target_company public.companies%rowtype;
  latest_summary text;
  promises jsonb;
  visit_ids uuid[];
begin
  select * into target_company from public.companies where id = target_company_id;
  if not found then raise exception 'Firma bulunamadı'; end if;

  select
    coalesce(v.ai_summary ->> 'summary', v.manual_notes, 'Onaylı ziyaret kaydı mevcut.'),
    coalesce(v.ai_summary -> 'promises', '[]'::jsonb)
  into latest_summary, promises
  from public.visits v
  where v.company_id = target_company_id and v.status = 'approved'
  order by v.approved_at desc
  limit 1;

  if latest_summary is null then return; end if;

  select array_agg(recent.id order by recent.approved_at desc)
  into visit_ids
  from (
    select id, approved_at from public.visits
    where company_id = target_company_id and status = 'approved'
    order by approved_at desc limit 10
  ) recent;

  insert into public.customer_memory_cards (
    company_id, workspace_id, organization_id, summary, open_promises,
    source_visit_ids, generated_at, stale_after
  ) values (
    target_company.id, target_company.workspace_id, target_company.organization_id,
    latest_summary, promises, coalesce(visit_ids, '{}'), now(), now() + interval '7 days'
  )
  on conflict (company_id) do update set
    summary = excluded.summary,
    open_promises = excluded.open_promises,
    source_visit_ids = excluded.source_visit_ids,
    generated_at = excluded.generated_at,
    stale_after = excluded.stale_after,
    updated_at = now();
end;
$$;

create or replace function public.on_visit_approved_refresh_memory()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    perform public.refresh_customer_memory_card(new.company_id);
  end if;
  return new;
end;
$$;

create trigger visit_approved_refresh_memory
after update of status on public.visits
for each row execute function public.on_visit_approved_refresh_memory();

revoke all on function public.refresh_customer_memory_card(uuid) from public;
revoke all on function public.on_visit_approved_refresh_memory() from public;

commit;
