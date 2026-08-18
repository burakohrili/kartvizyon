# Supabase production migration uygulaması

Uygulanacak üç migration ve **kesin sırası**. Supabase Dashboard → SQL Editor'de
her dosyanın içeriğini **tek tek** yapıştırıp çalıştırın. Hepsi `begin; ... commit;`
ile sarılıdır; hata olursa o migration bütünüyle geri alınır.

| Sıra | Dosya                                                              | Ne yapar                                                       |
| ---: | ------------------------------------------------------------------ | -------------------------------------------------------------- |
|    1 | `packages/database/migrations/0019_account_deletion.up.sql`        | Hesap silme için FK cascade/set null düzeni, `resolution_note` |
|    2 | `packages/database/migrations/0020_webhook_status_enum_fix.up.sql` | Webhook tetikleyicisini enum tiplerinde çalışır hale getirir   |
|    3 | `packages/database/migrations/0021_entitlements.up.sql`            | Plan limitleri, deneme, ek AI paketleri, koltuk kontrolü       |

Geri alma dosyaları aynı klasörde `.down.sql` uzantısıyla, ters sırada çalıştırılır.

## Önce: hangileri zaten uygulanmış?

Bu sorguyu SQL Editor'de çalıştırın. Yalnız `false` dönenleri uygulayın.

```sql
select
  exists (select 1 from information_schema.columns
          where table_name = 'privacy_requests'
            and column_name = 'resolution_note')                       as m0019_uygulandi,
  coalesce((select prosrc like '%::text%' from pg_proc
            where proname = 'enqueue_webhook_event'), false)           as m0020_uygulandi,
  exists (select 1 from information_schema.columns
          where table_name = 'subscription_plans'
            and column_name = 'max_companies')                         as m0021_uygulandi;
```

## Uyarı: 0019 iki kez çalıştırılamaz

`0019_account_deletion.up.sql` 32 adet `alter table ... drop constraint` ifadesi
içerir ve bunlarda `if exists` **yoktur**. Zaten uygulanmışsa ikinci çalıştırma
`constraint does not exist` hatasıyla durur. Bu tehlikeli değildir (transaction
geri alınır) ama yukarıdaki kontrol sorgusu `true` diyorsa 0019'u atlayın.

`0020` (`create or replace function`) ve `0021` (`add column if not exists`,
`on conflict do update`) tekrar çalıştırmaya dayanıklıdır.

## Sonra: doğrulama

```sql
-- Üçü de true olmalı
select
  exists (select 1 from information_schema.columns
          where table_name='privacy_requests' and column_name='resolution_note') as m0019,
  (select prosrc like '%::text%' from pg_proc where proname='enqueue_webhook_event') as m0020,
  exists (select 1 from information_schema.columns
          where table_name='subscription_plans' and column_name='max_companies') as m0021;

-- Plan tohumları yerinde mi
select id, name, monthly_price_try, min_seats, max_companies, max_ocr, distribution
from public.subscription_plans order by monthly_price_try;

-- Ek AI paketleri
select * from public.ai_topup_packages;

-- RLS'siz tablo kalmamalı (boş dönmeli)
select tablename from pg_tables where schemaname='public' and rowsecurity=false;
```

Beklenen plan tablosu: `free` 0 ₺ · `individual` 349 ₺ · `team` 279 ₺/koltuk (min 3)
· `enterprise` 449 ₺/koltuk (min 10). `starter` ve `growth` satırları `active=false`
olarak kalır.

## Sonrası

0021 uygulandıktan sonra `/api/settings/billing` yanıtı `entitlement` ve
`topUpPackages` alanlarını taşımaya başlar; kota kapısı devreye girer.
Günlük `03:30 UTC` cron'u (`/api/internal/subscriptions/expire-trials`) süresi
dolan denemeleri ücretsiz katmana düşürür.
