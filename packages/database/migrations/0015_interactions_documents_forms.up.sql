begin;

create type public.document_scan_status as enum ('pending', 'clean', 'blocked', 'failed');

create table public.activity_comments (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  visit_id uuid not null references public.visits(id) on delete cascade,
  author_id uuid not null references public.profiles(id),
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);

create index activity_comments_visit_idx on public.activity_comments(visit_id, created_at);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null check (char_length(title) between 2 and 180),
  body text not null check (char_length(body) between 1 and 1000),
  resource_type text,
  resource_id text,
  action_url text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_unread_idx on public.notifications(user_id, created_at desc) where read_at is null;

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  company_id uuid references public.companies(id) on delete cascade,
  visit_id uuid references public.visits(id) on delete set null,
  order_draft_id uuid references public.order_drafts(id) on delete set null,
  owner_id uuid not null references public.profiles(id),
  file_name text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 20971520),
  sha256 text not null check (sha256 ~ '^[a-f0-9]{64}$'),
  storage_path text not null unique,
  scan_status public.document_scan_status not null default 'pending',
  retained_until timestamptz,
  created_at timestamptz not null default now()
);

create index documents_company_idx on public.documents(company_id, created_at desc);

create table public.form_templates (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 160),
  description text,
  version integer not null default 1 check (version > 0),
  fields jsonb not null check (jsonb_typeof(fields) = 'array' and jsonb_array_length(fields) between 1 and 100),
  active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, name, version)
);

create table public.form_submissions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  template_id uuid not null references public.form_templates(id),
  company_id uuid references public.companies(id) on delete cascade,
  visit_id uuid references public.visits(id) on delete set null,
  submitted_by uuid not null references public.profiles(id),
  data jsonb not null check (jsonb_typeof(data) = 'object'),
  submitted_at timestamptz not null default now()
);

create index form_submissions_template_idx on public.form_submissions(template_id, submitted_at desc);

create or replace function public.create_activity_comment(target_visit_id uuid, comment_body text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  target_visit public.visits%rowtype;
  comment_id uuid;
begin
  select * into target_visit from public.visits where id = target_visit_id and status = 'approved';
  if not found or not public.can_access_workspace(target_visit.workspace_id) then raise exception 'Onaylı ziyaret bulunamadı'; end if;
  if char_length(trim(comment_body)) < 1 or char_length(trim(comment_body)) > 2000 then raise exception 'Yorum geçersiz'; end if;
  insert into public.activity_comments (workspace_id, organization_id, visit_id, author_id, body)
  values (target_visit.workspace_id, target_visit.organization_id, target_visit_id, auth.uid(), trim(comment_body)) returning id into comment_id;
  if target_visit.representative_id <> auth.uid() then
    insert into public.notifications (workspace_id, organization_id, user_id, type, title, body, resource_type, resource_id, action_url)
    values (target_visit.workspace_id, target_visit.organization_id, target_visit.representative_id, 'manager_comment', 'Ziyaretinize yorum geldi', left(trim(comment_body), 1000), 'visit', target_visit_id::text, '/activity');
  end if;
  insert into public.audit_logs (organization_id, workspace_id, actor_id, action, resource_type, resource_id)
  values (target_visit.organization_id, target_visit.workspace_id, auth.uid(), 'visit.comment_created', 'activity_comment', comment_id::text);
  return comment_id;
end;
$$;

alter table public.activity_comments enable row level security;
alter table public.notifications enable row level security;
alter table public.documents enable row level security;
alter table public.form_templates enable row level security;
alter table public.form_submissions enable row level security;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'document-quarantine',
  'document-quarantine',
  false,
  20971520,
  array[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do nothing;

create policy comments_scope_read on public.activity_comments for select using (public.can_access_workspace(workspace_id));
create policy notifications_owner_all on public.notifications for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy documents_scope_read on public.documents for select using (public.can_access_workspace(workspace_id));
create policy documents_owner_insert on public.documents for insert with check (owner_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy documents_owner_update on public.documents for update using (owner_id = auth.uid() and public.can_access_workspace(workspace_id)) with check (owner_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy form_templates_scope_all on public.form_templates for all using (public.can_access_workspace(workspace_id)) with check (public.can_access_workspace(workspace_id));
create policy form_submissions_scope_all on public.form_submissions for all using (public.can_access_workspace(workspace_id)) with check (submitted_by = auth.uid() and public.can_access_workspace(workspace_id));

create policy document_quarantine_owner_insert on storage.objects for insert to authenticated
with check (bucket_id = 'document-quarantine' and (storage.foldername(name))[1] = auth.uid()::text);

create policy document_clean_scope_read on storage.objects for select to authenticated
using (
  bucket_id = 'document-quarantine' and exists (
    select 1 from public.documents d
    where d.storage_path = name
      and d.scan_status = 'clean'
      and public.can_access_workspace(d.workspace_id)
  )
);

create policy document_quarantine_owner_delete on storage.objects for delete to authenticated
using (bucket_id = 'document-quarantine' and (storage.foldername(name))[1] = auth.uid()::text);

revoke all on function public.create_activity_comment(uuid, text) from public;
grant execute on function public.create_activity_comment(uuid, text) to authenticated;

commit;
