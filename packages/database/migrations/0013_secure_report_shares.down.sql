begin;

drop function if exists public.get_shared_report(text);
drop function if exists public.record_report_export(uuid, text, jsonb);
drop function if exists public.revoke_report_share(uuid);
drop function if exists public.create_report_share(uuid, text, text, jsonb, integer);
drop table if exists public.report_shares;

commit;
