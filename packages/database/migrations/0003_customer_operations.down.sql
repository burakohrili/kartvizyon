begin;

revoke execute on function public.find_company_duplicates(uuid, text, text, text) from authenticated;
drop function if exists public.find_company_duplicates(uuid, text, text, text);
drop index if exists public.companies_idempotency_idx;
alter table public.companies drop column if exists client_mutation_id;

commit;
