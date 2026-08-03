begin;

drop function if exists public.claim_document_scan_jobs(integer);
drop index if exists public.documents_scan_queue_idx;
alter table public.documents
  drop column if exists scanner_signature,
  drop column if exists scan_error,
  drop column if exists scan_attempts,
  drop column if exists scan_completed_at,
  drop column if exists scan_started_at;

-- PostgreSQL enum değerleri güvenli biçimde geri alınamadığı için 'processing'
-- değeri kasıtlı olarak korunur; uygulama geri dönüşünde kullanılmaz.

commit;
