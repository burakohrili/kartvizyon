begin;

alter table public.tasks
  add column source text not null default 'manual' check (source in ('manual', 'ai_follow_up')),
  add column source_follow_up_index integer check (source_follow_up_index is null or source_follow_up_index >= 0);

create unique index tasks_ai_follow_up_unique
on public.tasks(visit_id, source_follow_up_index)
where source = 'ai_follow_up';

create or replace function public.create_tasks_from_approved_visit()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  follow_up record;
  follow_up_title text;
  follow_up_date date;
begin
  if new.status <> 'approved' or old.status = 'approved' then return new; end if;
  for follow_up in
    select value, ordinality - 1 as item_index
    from jsonb_array_elements(coalesce(new.ai_summary -> 'followUps', '[]'::jsonb)) with ordinality
  loop
    follow_up_title := trim(follow_up.value ->> 'title');
    if follow_up_title is null or follow_up_title = '' then continue; end if;
    begin
      follow_up_date := nullif(follow_up.value ->> 'dueDate', '')::date;
    exception when invalid_datetime_format then
      follow_up_date := null;
    end;
    insert into public.tasks (
      workspace_id, organization_id, company_id, visit_id, title, due_at,
      assigned_to, created_by, source, source_follow_up_index
    ) values (
      new.workspace_id, new.organization_id, new.company_id, new.id,
      left(follow_up_title, 180),
      case when follow_up_date is null then null else follow_up_date::timestamptz + interval '9 hours' end,
      new.representative_id, coalesce(new.approved_by, new.representative_id),
      'ai_follow_up', follow_up.item_index
    ) on conflict (visit_id, source_follow_up_index) where source = 'ai_follow_up' do nothing;
  end loop;
  return new;
end;
$$;

create trigger approved_visit_create_tasks
after update of status on public.visits
for each row execute function public.create_tasks_from_approved_visit();

revoke all on function public.create_tasks_from_approved_visit() from public;

commit;
