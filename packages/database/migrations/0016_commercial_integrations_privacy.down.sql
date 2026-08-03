begin;
drop policy if exists privacy_export_owner_read on storage.objects;
delete from storage.buckets where id = 'privacy-exports';
drop policy if exists usage_workspace_admin_read on public.usage_records;
alter table public.usage_records drop constraint if exists usage_records_metric_check;
alter table public.usage_records add constraint usage_records_metric_check
  check (metric in ('audio_seconds', 'input_tokens', 'output_tokens'));
drop function if exists public.is_workspace_admin(uuid);
drop table if exists public.privacy_requests;
drop table if exists public.user_consents;
drop table if exists public.webhook_deliveries;
drop table if exists public.webhook_endpoints;
drop table if exists public.api_credentials;
drop table if exists public.workspace_subscriptions;
drop table if exists public.subscription_plans;
drop type if exists public.privacy_request_status;
drop type if exists public.privacy_request_kind;
drop type if exists public.subscription_status;
commit;
