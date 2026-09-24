begin;
drop policy if exists subscription_storage_insert on storage.objects;
drop policy if exists subscription_storage_update on storage.objects;
drop function if exists public.has_writable_workspace();
do $$ declare tab text; begin
  foreach tab in array array['companies','contacts','visits','tasks','customer_memory_cards','import_jobs','geofence_events','visit_audio_assets','visit_transcripts','ai_jobs','debrief_submissions','report_shares','opportunities','products','price_lists','order_drafts','activity_comments','documents','form_templates','form_submissions','api_credentials','webhook_endpoints','regions','teams'] loop
    execute format('drop trigger if exists subscription_write_guard on public.%I',tab);
  end loop;
end $$;
drop function if exists public.require_workspace_subscription();
drop function if exists public.workspace_usage(uuid);
drop function if exists public.reserve_ai_quota(uuid,uuid,text,integer,integer,integer);
drop function if exists public.workspace_entitlement(uuid);
drop function if exists public.usage_month_start(timestamptz,timestamptz);
drop trigger if exists start_account_trial on auth.users;
drop function if exists public.start_account_trial();
-- Deneme geçmişi ve maliyet/tüketim kayıtları rollback sırasında silinmez.
-- Tekrar ileri geçişten önce bu saklanan tablolar kontrollü olarak taşınmalıdır.
update public.subscription_plans set monthly_price_try=349,price_per_seat_try=349,annual_price_try=3490,monthly_ai_minutes=120,max_ocr=60 where id='individual';
do $$ begin
  if to_regclass('public.billing_product_mappings') is not null then
    update public.billing_product_mappings set active=true where billing_period='annual';
  end if;
end $$;
update public.subscription_plans set name='Ücretsiz',monthly_ai_minutes=10,max_ocr=5,max_companies=5 where id='free';
update public.ai_topup_packages set active=true;
commit;
