# Operasyon rehberi

## Ortam değişkenleri

Yerel web değerlerini `apps/web/.env.local` içine kaydedin ve gizli değerleri depoya eklemeyin. `.gitignore` içindeki `.env*` kuralı gereği depoda örnek env dosyası tutulmaz; gerekli değişkenlerin tam listesi `docs/EXTERNAL_SETUP_RUNBOOK.md` §2 içindedir. Web için Supabase URL/publishable anahtarı ve AI için `OPENAI_API_KEY` gerekir. Mobil değerler `--dart-define` ile verilir:

```powershell
flutter run --dart-define=KARTVIZYON_API_URL=https://app.kartvizyon.app --dart-define=SUPABASE_URL=https://project.supabase.co --dart-define=SUPABASE_ANON_KEY=... --dart-define=SENTRY_DSN=...
```

## Migration ve sağlık

Migrationları numara sırasıyla uygulayın; her `.up.sql` dosyasının `.down.sql` geri alımı vardır. Production öncesi yedek ve staging provası yapın.

- `GET /api/health`: sürüm, uptime ve veritabanı yapılandırması.
- `GET /api/openapi`: temel API sözleşmesi.
- Yanıtlar `x-request-id` taşır; API çağrıları aynı kimlikle JSON log üretir.
- `429` yanıtı `Retry-After: 60` taşır.

## Production zamanlayıcıları

Vercel cronları aşağıdaki uçlara `GET` gönderir; rotalar aynı işleyiciyi `POST` için de sunar. Vercel, `CRON_SECRET` tanımlandığında `Authorization: Bearer` başlığını ekler:

- `GET|POST /api/internal/retention/audio` — günlük 02:00 UTC, `CRON_SECRET`
- `GET|POST /api/internal/privacy/process` — 10 dakikada bir, `CRON_SECRET` veya `PRIVACY_WORKER_SECRET`
- `GET|POST /api/internal/webhooks/deliver` — 5 dakikada bir, `CRON_SECRET` veya `WEBHOOK_WORKER_SECRET`
- `GET|POST /api/internal/documents/dispatch` — 5 dakikada bir, `CRON_SECRET`; private ClamAV servisini çağırır
- `GET|POST /api/internal/subscriptions/expire-trials` — günlük 03:30 UTC, `CRON_SECRET`; süresi dolan 14 günlük denemeleri ücretsiz katmana düşürür (ADR-0005)
- `POST /api/internal/documents/scan-jobs` — tarayıcı iş sahiplenme, `DOCUMENT_SCAN_SECRET`
- `POST /api/internal/documents/scan-result` — ClamAV callback, `DOCUMENT_SCAN_SECRET`

Belge tarayıcı `services/document-scanner` container’ıdır. `/health` public olabilir; `/scan` daima bearer secret ister. Callback hedefi istekten değil yalnız `APP_BASE_URL=https://app.kartvizyon.app` ortam değişkeninden okunur. Production deploy sonrası URL `DOCUMENT_SCAN_SERVICE_URL` olarak Vercel’e eklenir. EICAR test dosyası `blocked`, temiz PDF `clean`, bozuk/erişilemeyen dosya `failed` vermeden yayın kapısı geçmez. Cloud Run komutları `services/document-scanner/README.md` içindedir.

Webhook sırları `INTEGRATION_ENCRYPTION_KEY` ile AES-256-GCM şifrelenir. Bu anahtar 32 rastgele baytın Base64 karşılığı olmalı, secret manager dışında tutulmamalı ve kaybedilmemelidir.

## AI model ve bütçe

Varsayılan modeller ve gerekçeleri `docs/product/decisions/0005-pricing.md` içindedir.
Üçü de ortam değişkeniyle override edilir:

| Değişken                     | Varsayılan          | İş                 |
| ---------------------------- | ------------------- | ------------------ |
| `OPENAI_SUMMARY_MODEL`       | `gpt-5.6-terra`     | Ziyaret özeti      |
| `OPENAI_OCR_MODEL`           | `gpt-5.6-luna`      | Kartvizit OCR      |
| `OPENAI_TRANSCRIPTION_MODEL` | `gpt-4o-transcribe` | Ses transkripsiyon |

OpenAI hesabında aylık **$50 hard limit** ve $30'da e-posta uyarısı tanımlı olmalıdır.
Kota tükendiğinde uygulama manuel ziyaret kaydına düşer; AI olmadan da çalışır.

## Plan limitleri

`apps/web/src/lib/entitlements.ts` tek doğruluk kaynağıdır. Limit aşımı `402` ve
`code: "quota_exceeded"` döndürür; mobil istemci bu koda göre bilgilendirme
gösterir. Koltuk limiti `accept_invitation` fonksiyonunda uygulanır — API
katmanındaki kontrol anon anahtarla RPC çağrısıyla atlatılabileceği için
veritabanı seviyesinde tutulur.

## Mobil doğrulama

```powershell
Set-Location apps/mobile
flutter analyze
flutter test
flutter build apk --debug
```

iOS build/signing Codemagic macOS/Xcode worker’da yapılır. `codemagic.yaml` workflow’ları KartVizyon’a ait `app.kartvizyon.mobile`, `kartvizyon_upload` ve `kartvizyon_app_store` referansları dışında signing kimliği kabul etmez.

## Müşteri konumu

Yakınlık hatırlatması yalnız koordinatı olan müşteriler için çalışır
(`/api/geofence/candidates` `latitude is not null` filtresi uygular). Koordinat
iki yoldan gelir ve kaynağı `companies.location_source` alanında tutulur:

| Kaynak     | Nasıl                                                      | Güvenilirlik |
| ---------- | ---------------------------------------------------------- | ------------ |
| `geocoded` | Müşteri kaydedilirken adres metninden çözülür              | Tahmin       |
| `pinned`   | Saha çalışanı müşteri kartında "Konumu buraya sabitle" der | Kesin        |

**Sahada sabitlenen konum tahmini ezer**; tersi olmaz.

Geocoding `GOOGLE_GEOCODING_API_KEY` ortam değişkenine bağlıdır. Anahtar
tanımlı değilse `geocodeAddress` sessizce `null` döner ve müşteri koordinatsız
kaydedilir — geocoding hiçbir koşulda kayıt oluşturmayı engellemez. Zaman aşımı
4 saniyedir; kota dolması, ağ hatası ve `ZERO_RESULTS` de aynı şekilde yutulur.

Maliyet kontrolü: 8 karakterden kısa adresler için istek atılmaz, istek yalnız
kayıt anında bir kez yapılır. Google Geocoding ücreti ~$5/1000 istektir.

Anahtar Cloud Console'da **yalnız Geocoding API'ye kısıtlanmış** olmalıdır.

## Domain ve e-posta

- `kartvizyon.app`: public site ve legal/store URL’leri
- `app.kartvizyon.app`: uygulama; Vercel hostname rewrite ile `/dashboard`
- `auth.kartvizyon.app`: Resend gönderim alanı
- Supabase sender: `KartVizyon <no-reply@auth.kartvizyon.app>`
- Destek geçici adresi: `kartvizyonapp@gmail.com`; satın alınmış mailbox olmadan gelen yanıt için `support@kartvizyon.app` kullanılmaz.

## Olay müdahalesi

1. `/api/health`, Vercel deployment/runtime logları ve Sentry issue durumunu kontrol edin.
2. `x-request-id` ile tek isteği izleyin; secret, ses, transkript veya belge gövdesini loga kopyalamayın.
3. 5xx artışında son sağlam Vercel deployment’a rollback; migration geri alma yalnız backup ve veri etkisi kontrolünden sonra.
4. Cron alarmında endpoint’i aynı bearer ile bir kez manuel çalıştırın; başarısız işi körlemesine döngüye sokmayın.
5. Olay sonrası süre, kapsam, kullanıcı etkisi, kök neden ve önleyici aksiyonu kaydedin.

## Hesap silme

Migration `0019_account_deletion` ve privacy worker birlikte yayınlanır. Kişisel çalışma alanı hesapla birlikte cascade silinir; kurumsal satış kayıtlarında kullanıcı atıfları `NULL` yapılarak anonimleştirilir. Ham ses, transkript, AI işi ve kullanıcı storage nesneleri silinir. Aktif organizasyon sahibi için talep reddedilir ve sahiplik devri istenir. Production'da migration uygulanmadan worker deploy edilmez.

## Sentry

Web ve mobil SDK yalnız DSN tanımlıyken production'da etkinleşir. Varsayılan PII gönderimi, ekran görüntüsü ve view hierarchy kapalıdır; web request body/cookie ve hassas header/extra alanları filtrelenir. Sentry projesi açıldıktan sonra web için `NEXT_PUBLIC_SENTRY_DSN`, source map için `SENTRY_ORG`, `SENTRY_PROJECT`, `SENTRY_AUTH_TOKEN`; mobil için Codemagic `SENTRY_DSN` girilir. Kritik alarm: yeni regression, 5xx artışı ve cron/scan/deletion hata olayları.
