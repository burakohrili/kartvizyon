# Yayın öncesi test rehberi

Bu belge yayına çıkmadan önce geçmesi gereken kontrolleri, hangisinin otomatik
hangisinin elle yapıldığını ayırt ederek listeler.

## 1. Otomatik kapı — `npm run check`

Tek komut; sırayla format, migration/rollback, lint, tip, test, production build,
sır sızıntısı taraması ve Flutter analiz/testlerini çalıştırır.

| Aşama                | Kapsam                                               |
| -------------------- | ---------------------------------------------------- |
| `format:check`       | Tüm depo (CRLF/LF `.gitattributes` ile normalize)    |
| `migration:validate` | 21 up/down çifti, transaction ve RLS zorunluluğu     |
| `lint` + `typecheck` | web, contracts, database                             |
| `test`               | 263 test (aşağıda dökümü)                            |
| `build`              | Next.js production derlemesi                         |
| `verify:secrets`     | Derlenmiş istemci varlıklarında sunucu sırrı araması |
| `mobile:check`       | `flutter analyze` + 24 mobil test                    |

### Test dökümü

| Paket / dosya                                 | Test | Neyi korur                                             |
| --------------------------------------------- | ---: | ------------------------------------------------------ |
| `packages/database/tests/security-invariants` |  122 | RLS kapsamı, policy, `search_path`, kova gizliliği     |
| `packages/database/tests/migrations`          |   78 | Şema sözleşmeleri ve rollback bütünlüğü                |
| `packages/contracts/src/contracts`            |   23 | Durum makineleri, roller, domain doğrulaması           |
| `apps/web/src/lib/entitlements`               |   10 | Plan limitleri, deneme, kota, koltuk, ek paket         |
| `apps/web/src/lib/openai/prompt-safety`       |    6 | Prompt injection, `needs_review`, AI kesintisi         |
| `apps/web/src/lib/openai/business-card`       |    5 | OCR şema doğrulaması                                   |
| `apps/web/src/lib/*` (diğer)                  |   19 | İçe aktarma ayrıştırma, public URL, OpenAI istemcisi   |
| `apps/mobile/test/ux_resilience`              |    8 | Dar ekran, 2× yazı tipi, form doğrulama, boş durumlar  |
| `apps/mobile/test/*` (diğer)                  |   16 | Offline kuyruk, senkron, oturum yenileme, mağaza uyumu |

### Otomatik kapının yakaladığı gerçek hatalar

Bu testler yazılırken üründe bulunan ve düzeltilen kusurlar:

1. Müşteri ekleme dialogunda klavye boşluğunun iki kez uygulanması (boş ekran).
2. Dar ekranda (360 dp) dialog buton satırının taşması.
3. Sistem yazı tipi 2× yapıldığında alt navigasyon çubuğunun 59 px taşması.
4. Ziyaret özeti isteminde prompt injection korumasının bulunmaması.

## 2. Elle yapılması gereken — veri sızıntısı

Statik testler şemayı denetler ama **gerçek RLS davranışını** yalnız canlı bir
Postgres doğrular. Staging projesinde bir kez çalıştırın:

1. İki ayrı kullanıcı ve iki ayrı organizasyon/çalışma alanı oluşturun.
2. A kullanıcısının anon anahtarla oturumuyla, B'nin `workspace_id`'sini kullanarak
   her tablo için `select`, `insert`, `update`, `delete` deneyin. Hepsi boş sonuç
   veya hata dönmelidir.
3. `accept_invitation` RPC'sini doğrudan çağırıp koltuk limitinin uygulandığını
   doğrulayın (API'yi atlayarak).
4. Ses ve belge kovalarından imzasız URL ile dosya indirmeyi deneyin — reddedilmeli.
5. `service_role` anahtarının yalnız Vercel sunucu ortamında bulunduğunu,
   hiçbir istemci ortam değişkeninde `NEXT_PUBLIC_` önekiyle tanımlı olmadığını
   doğrulayın.

Ek kontrol sorgusu (Supabase SQL Editor):

```sql
-- RLS'siz tablo kalmamalı
select tablename from pg_tables
where schemaname = 'public' and rowsecurity = false;

-- search_path sabitlenmemiş security definer fonksiyon kalmamalı
select proname from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.prosecdef
  and not exists (select 1 from unnest(coalesce(p.proconfig, '{}'))
                  as c where c like 'search_path=%');

-- Uygulanmış migration doğrulaması
select
  exists (select 1 from information_schema.columns
          where table_name='privacy_requests' and column_name='resolution_note') as m0019,
  (select prosrc like '%::text%' from pg_proc where proname='enqueue_webhook_event') as m0020,
  exists (select 1 from information_schema.columns
          where table_name='subscription_plans' and column_name='max_companies') as m0021;
```

## 3. Elle yapılması gereken — API yetkilendirme

Production'a karşı, oturum açmadan:

- Her `/api/*` ucu `401` dönmeli (`/api/health` ve `/api/openapi` hariç).
- `/api/internal/*` uçları bearer secret olmadan `401` dönmeli.
- Süresi dolmuş veya iptal edilmiş rapor paylaşım tokenı `410`/`404` dönmeli.
- 120 istek/dakika üstünde `429` + `Retry-After: 60` dönmeli.

## 4. Elle yapılması gereken — kota davranışı

Ücretsiz katmandaki bir hesapla:

- 5. müşteri kaydedilir, 6.'da `402` ve `code: "quota_exceeded"` döner.
- Deneme süresi aktifken 6. müşteri de kaydedilir.
- AI dakikası dolduğunda sesli debrief `402` döner ama **metin notu çalışmaya devam eder**.
- Mevcut kayıtlar hiçbir koşulda silinmez veya erişilemez hale gelmez.

## 5. Elle yapılması gereken — gerçek cihaz

| Senaryo                        | Beklenen                                                               |
| ------------------------------ | ---------------------------------------------------------------------- |
| Uçak modunda ziyaret + debrief | Kuyruğa girer, bağlantıda idempotent senkronize olur, çift kayıt olmaz |
| Kamera izni reddi              | Galeri ve manuel giriş alternatifi açılır                              |
| Mikrofon izni reddi            | Metin notu alternatifi açılır                                          |
| Konum izni reddi               | Arama ve manuel adres alternatifi açılır                               |
| Oturum süresi dolması          | Sessiz yenileme; başarısızsa login'e yönlendirme                       |
| Sistem yazı tipi en büyük      | Hiçbir ekranda kesme/taşma yok                                         |
| Koyu tema                      | Kontrast okunabilir                                                    |
| Düşük/orta segment Android     | Ana akışlar takılmadan çalışır                                         |

En az bir gerçek iPhone (TestFlight) ve bir düşük segment Android cihaz gerekir.

## 6. Elle yapılması gereken — mağaza uyumu

- Mobil binary'de fiyat/satın alma dizesi ve pazarlama sitesi bağlantısı yok
  (otomatik test var; yeni ekran eklendiğinde tekrar çalıştırılır).
- App Store Connect App Privacy formu SDK envanteriyle birebir aynı.
- Play Data safety beyanı aynı envanterle tutarlı.
- Reviewer hesabıyla uçtan uca giriş → demo veri → KVKK akışı çalışıyor.

## 7. Yayın kapısı özeti

- [ ] `npm run check` tam yeşil
- [ ] Bölüm 2 canlı RLS testleri geçti
- [ ] Bölüm 3 API yetkilendirme kontrolleri geçti
- [ ] Bölüm 4 kota davranışı doğrulandı
- [ ] Bölüm 5 gerçek cihaz turu tamamlandı
- [ ] Supabase `0019`, `0020`, `0021` migration'ları uygulandı
- [ ] Codemagic her iki workflow yeşil, yeni AAB/IPA üretildi
- [ ] App Store Connect alanları dolu (`docs/APPLE_SUBMISSION_CHECKLIST.md`)
- [ ] Play içerik derecelendirmesi ve 12 test kullanıcısı × 14 gün tamamlandı
