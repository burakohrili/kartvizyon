begin;

drop function if exists public.apply_store_billing_event(text,text,text,text,text,uuid,uuid,text,text,text,text,text,public.subscription_status,timestamptz,timestamptz,boolean,timestamptz);
drop table if exists public.store_purchases;
drop table if exists public.billing_events;
drop table if exists public.billing_product_mappings;

update public.subscription_plans set distribution = 'web' where id = 'individual';
alter table public.subscription_plans drop constraint if exists subscription_plans_distribution_check;
alter table public.subscription_plans add constraint subscription_plans_distribution_check
  check (distribution in ('free', 'iap', 'web'));

-- Güvenlik düzeltmesi rollback sırasında da korunur: istemci abonelik yazma
-- yetkisi geri verilmez.

commit;
