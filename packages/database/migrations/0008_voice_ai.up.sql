begin;

create type public.ai_job_kind as enum ('transcription', 'visit_summary');
create type public.ai_job_status as enum ('queued', 'processing', 'completed', 'failed');

create table public.visit_audio_assets (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references public.visits(id) on delete cascade,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  owner_id uuid not null references public.profiles(id),
  storage_path text not null unique,
  mime_type text not null,
  byte_size bigint not null check (byte_size between 1 and 26214400),
  sha256 text not null check (sha256 ~ '^[a-f0-9]{64}$'),
  delete_after timestamptz not null default (now() + interval '30 days'),
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.visit_transcripts (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null unique references public.visits(id) on delete cascade,
  audio_asset_id uuid references public.visit_audio_assets(id) on delete set null,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  owner_id uuid not null references public.profiles(id),
  transcript text not null check (char_length(transcript) between 10 and 20000),
  language text not null default 'tr',
  provider text,
  model text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.ai_jobs (
  id uuid primary key default gen_random_uuid(),
  visit_id uuid not null references public.visits(id) on delete cascade,
  audio_asset_id uuid references public.visit_audio_assets(id) on delete set null,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  kind public.ai_job_kind not null,
  status public.ai_job_status not null default 'queued',
  provider text not null default 'openai',
  model text not null,
  attempts integer not null default 0 check (attempts between 0 and 10),
  error_code text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.usage_records (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  visit_id uuid references public.visits(id) on delete set null,
  metric text not null check (metric in ('audio_seconds', 'input_tokens', 'output_tokens')),
  quantity numeric(14, 3) not null check (quantity >= 0),
  unit text not null,
  provider text not null default 'openai',
  model text not null,
  occurred_at timestamptz not null default now()
);

create index visit_audio_owner_idx on public.visit_audio_assets(owner_id, created_at desc);
create index ai_jobs_visit_idx on public.ai_jobs(visit_id, created_at desc);
create index usage_records_org_period_idx on public.usage_records(organization_id, occurred_at desc);

alter table public.visit_audio_assets enable row level security;
alter table public.visit_transcripts enable row level security;
alter table public.ai_jobs enable row level security;
alter table public.usage_records enable row level security;

-- Raw audio and transcripts remain private working material, including from managers.
create policy visit_audio_owner_only on public.visit_audio_assets for all
using (owner_id = auth.uid() and public.can_access_workspace(workspace_id))
with check (owner_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy visit_transcript_owner_only on public.visit_transcripts for all
using (owner_id = auth.uid() and public.can_access_workspace(workspace_id))
with check (owner_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy ai_jobs_owner_only on public.ai_jobs for all
using (user_id = auth.uid() and public.can_access_workspace(workspace_id))
with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy usage_records_owner_read on public.usage_records for select
using (user_id = auth.uid() and public.can_access_workspace(workspace_id));
create policy usage_records_owner_insert on public.usage_records for insert
with check (user_id = auth.uid() and public.can_access_workspace(workspace_id));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'visit-audio',
  'visit-audio',
  false,
  26214400,
  array['audio/webm', 'audio/mp4', 'audio/x-m4a', 'audio/mpeg', 'audio/wav']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy visit_audio_object_owner_insert on storage.objects for insert to authenticated
with check (bucket_id = 'visit-audio' and (storage.foldername(name))[1] = auth.uid()::text);
create policy visit_audio_object_owner_read on storage.objects for select to authenticated
using (bucket_id = 'visit-audio' and (storage.foldername(name))[1] = auth.uid()::text);
create policy visit_audio_object_owner_delete on storage.objects for delete to authenticated
using (bucket_id = 'visit-audio' and (storage.foldername(name))[1] = auth.uid()::text);

commit;
