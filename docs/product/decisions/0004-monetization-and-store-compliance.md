# ADR-0004 — Bireysel IAP, kurumsal koltuk satışı ve mağaza uyumu

- Durum: kabul edildi
- Tarih: 3 Ağustos 2026
- Değiştirdiği karar: ADR-0003'ün "mobilde satın alma yok" maddesi

## Bağlam

ADR-0003 tüm satın almayı web'e almıştı. Kod incelemesi ve mağaza kuralları iki sorunu ortaya çıkardı:

1. **Bireysel dönüşüm kırılıyor.** App Store'dan indiren kullanıcının uygulama içinde ödeme yolu yok; siteye kendi başına gitmesi gerekiyor.
2. **Reddedilme riski.** Apple, web'de satın alınmış aboneliğe giriş yapılan companion app'leri 3.1.1'den düzenli reddediyor.

Mevcut kodda ticari model zaten kurulu ama **hiçbir limit uygulanmıyor**:

- `subscription_plans` — `seat_limit`, `monthly_ai_minutes`, `monthly_document_bytes` var
- `workspace_subscriptions` — `provider`, `provider_customer_id`, `provider_subscription_id`, `seat_quantity`, `trialing/active/past_due/cancelled` var
- `workspace_kind` — `personal` / `organization` ayrımı var
- `seat_limit` ve `monthly_ai_minutes` yalnızca [settings-workbench.tsx](../../../apps/web/src/app/settings/settings-workbench.tsx) ekranında görünüyor; tek bir akış bile kontrol etmiyor

Yani sıfırdan kurulum değil, eksik olan: **enforcement, ücretsiz katman, ödeme sağlayıcısı bağlantısı.**

## Karar

### 1. İki ayrı satış kanalı, tek entitlement kaynağı

| Kanal | Kim | Nasıl | Komisyon |
| --- | --- | --- | --- |
| **IAP** | Bireysel, mobilden gelen | Apple IAP / Google Play Billing | %15 (Small Business) |
| **Web (iyzico)** | Bireysel web'den gelen + tüm kurumsal | app.kartvizyon.app checkout | %0 |

Her iki kanal da aynı `workspace_subscriptions` satırını günceller. Uygulama tek yerden entitlement okur.

### 2. Mağaza reddini önleyen kural

Ayrım **`workspace_kind`** üzerinden yapılır — şema bu ayrımı zaten taşıyor:

```
kind = 'personal'      → mobilde IAP paywall gösterilebilir
kind = 'organization'  → mobilde HİÇBİR satın alma yüzeyi yok
```

Kurumsal üye limite çarptığında yalnızca bilgilendirme görür: *"Planınız kurum yöneticiniz tarafından yönetiliyor."* Buton yok, link yok, fiyat yok. Kurumsal koltuklar yönetici tarafından web'de satın alınır; bu, Apple'ın kurumsal/multiplatform istisnası kapsamındadır.

**Değişmez kural:** mobil uygulamada `kartvizyon.app` fiyat sayfasına giden tıklanabilir hiçbir öğe bulunmaz.

### 3. Ücretsiz katman: 14 gün tam erişim + sonrasında kullanım limitli

- Yeni kişisel çalışma alanı → `status='trialing'`, `trial_ends_at = now() + 14 gün`, tam erişim
- Deneme bitince → `plan_id='free'`, `status='active'`
- Ücretsiz katman limitleri: **5 müşteri, 2 sesli debrief, 1 koltuk**
- Veri silinmez; limit üstü **yeni kayıt oluşturmayı** engeller, mevcut kayıtlar okunabilir kalır

### 4. Kurumsal: koltuk bazlı self-serve (Claude Team modeli)

- Yönetici web'de koltuk sayısı seçer, iyzico ile öder
- `workspace_subscriptions.seat_quantity = N`
- Koltuk = `revoked_at IS NULL` olan her `memberships` satırı
- Koltuk dolduğunda davet kabulü engellenir
- Koltuk azaltma önce üye çıkarmayı gerektirir

## Sonuçlar

**Kabul edilen maliyetler**

- Mobilden gelen bireysel abonelikte %15 komisyon
- Apple/Google sunucu bildirimleri için iki yeni webhook ucu ve doğrulama yükü
- Aynı ürünün iki farklı fiyat noktası olabilir (IAP fiyatı komisyonu telafi edecek şekilde ayarlanabilir)

**Kazanımlar**

- Bireysel kullanıcı iki tıkta abone olur (Apple Pay / Google Pay)
- 3.1.1 reddi riski ortadan kalkar
- Kurumsal tarafta komisyon %0 kalır
- Mağaza formlarındaki "dijital satın alma" beyanı bir kez `Evet` yapılır ve tutarlı kalır

## Uygulama planı

### Faz A — Enforcement temeli (ödeme sağlayıcısından bağımsız)

Bu faz hiçbir dış hesap gerektirmez ve hemen başlayabilir.

1. **Önce defect düzeltmesi:** [`POST /api/customers`](../../../apps/web/src/app/api/customers/route.ts) `getApiContext` kullanmıyor, `workspaceId`'yi istek gövdesinden alıyor. Diğer rotalarla aynı desene çekilmeli — kota kontrolü buna bağlı.

2. **Migration `0020_entitlements`**
   - `subscription_plans`: `max_companies int`, `max_audio_assets int` (null = sınırsız), `price_per_seat_try numeric`, `distribution text check (in ('free','iap','web'))`
   - `workspace_subscriptions`: `trial_ends_at timestamptz`, `provider_original_transaction_id text`
   - Plan tohumları: `free`, `individual`, `team` (koltuk başı), `enterprise`
   - `.down.sql` ile birlikte

3. **`apps/web/src/lib/entitlements.ts`** — tek çözümleyici
   ```
   resolveEntitlement(supabase, workspaceId) → {
     planId, status, limits, trialActive, seatsPurchased, seatsUsed
   }
   ```
   Kurallar: `trialing` + `trial_ends_at > now()` → tam limit · `active` → plan limiti ·
   `past_due` → 7 gün ödemesiz devam · `cancelled` → `current_period_end`'e kadar · aksi → free

4. **`assertQuota(context, kind)`** — `402` ve makine-okunur hata kodu döner (mobil doğru paywall'ı seçsin diye)
   - `companies` → `companies` tablosunda canlı COUNT
   - `audio` → `visit_audio_assets` tablosunda canlı COUNT
   - `seats` → `memberships` (revoked_at null) COUNT

   Bağlanacağı rotalar: `POST /api/customers`, ziyaret debrief ses yükleme, `POST /api/documents`, `POST /api/invitations/accept`

5. **Deneme bitişi cron'u** — mevcut cron altyapısına eklenir (`docs/OPERATIONS.md` desenine uygun): süresi dolan `trialing` satırlarını `free`'ye düşürür

6. **Testler** — limit altında geçen / limit üstünde `402` dönen; deneme aktifken limitin uygulanmadığı; kurumsal alanda satın alma yüzeyi üretilmediğini doğrulayan regresyon testi

### Faz B — Web checkout (iyzico)

7. iyzico sandbox, ürün/plan tanımları
8. Koltuk seçimli checkout ekranı (`app.kartvizyon.app`), yalnız `kind='organization'` ve kişisel plan yükseltme
9. `POST /api/internal/webhooks/iyzico` — imza doğrulama, idempotency, audit; mevcut webhook desenini yeniden kullanır
10. Plan yükseltme / koltuk değiştirme / iptal ekranları
11. Fatura ve iade süreci (Noesis Social bilgileri, Türkiye mevzuatı)

### Faz C — Mobil IAP

12. Flutter `in_app_purchase` entegrasyonu; ürün: aylık ve yıllık bireysel abonelik
13. **Sunucu tarafı doğrulama** — istemci makbuzuna asla güvenilmez
    - `POST /api/internal/webhooks/apple` — App Store Server Notifications V2
    - `POST /api/internal/webhooks/google` — Play RTDN (Pub/Sub)
14. Paywall ekranı: yalnız `kind='personal'` iken açılır
15. Kurumsal üye için bilgilendirme ekranı (CTA'sız)
16. Satın alma geri yükleme (restore purchases) — Apple zorunlu tutar

## Doğrulama

- `npm.cmd run check` — lint, tip, test, migration/rollback, production build
- Kota testleri: 5. müşteri geçer, 6. `402` döner; deneme aktifken 6. da geçer
- Koltuk testi: `seat_quantity` dolduğunda davet kabulü reddedilir
- Mağaza kapısı: mobil binary'de fiyat/satın alma dizesi ve `kartvizyon.app` bağlantısı bulunmadığını doğrulayan test
- IAP: sandbox hesabıyla satın alma → sunucu bildirimi → entitlement güncellemesi uçtan uca

## Bekleyen kararlar

Fiyat noktaları henüz belirlenmedi. Faz B başlamadan netleşmeli:

- Bireysel aylık/yıllık fiyat (IAP fiyatı komisyonu telafi edecek şekilde web'den farklı olabilir)
- Kurumsal koltuk başı fiyat — mevcut `starter` 990 ₺ / `growth` 2490 ₺ tohumları sabit fiyatlı, koltuk başına çevrilmeli
- Enterprise eşiği (kaç koltuktan sonra satış görüşmesi)
