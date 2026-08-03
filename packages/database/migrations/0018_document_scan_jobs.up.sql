alter type public.document_scan_status add value if not exists 'processing' after 'pending';
commit;

begin;

alter table public.documents
  add column scan_started_at timestamptz,
  add column scan_completed_at timestamptz,
  add column scan_attempts integer not null default 0 check (scan_attempts between 0 and 10),
  add column scan_error text,
  add column scanner_signature text;

create index documents_scan_queue_idx
  on public.documents(scan_status, created_at)
  where scan_status in ('pending', 'processing');

create or replace function public.claim_document_scan_jobs(batch_size integer default 5)
returns setof public.documents
language plpgsql
security definer
set search_path = ''
as $$
begin
  if batch_size < 1 or batch_size > 20 then
    raise exception 'Geçersiz tarama parti boyutu';
  end if;

  update public.documents
  set scan_status = 'failed',
      scan_completed_at = now(),
      scan_error = 'Tarama üç denemeden sonra tamamlanamadı.'
  where scan_status = 'processing'
    and scan_started_at < now() - interval '15 minutes'
    and scan_attempts >= 3;

  return query
  with candidates as (
    select id
    from public.documents
    where scan_status = 'pending'
       or (
         scan_status = 'processing'
         and scan_started_at < now() - interval '15 minutes'
         and scan_attempts < 3
       )
    order by created_at
    for update skip locked
    limit batch_size
  )
  update public.documents d
  set scan_status = 'processing',
      scan_started_at = now(),
      scan_attempts = d.scan_attempts + 1,
      scan_error = null
  from candidates c
  where d.id = c.id
  returning d.*;
end;
$$;

revoke all on function public.claim_document_scan_jobs(integer) from public;
revoke all on function public.claim_document_scan_jobs(integer) from anon;
revoke all on function public.claim_document_scan_jobs(integer) from authenticated;
grant execute on function public.claim_document_scan_jobs(integer) to service_role;

commit;
