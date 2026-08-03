# Operasyon rehberi

## Ortam değişkenleri

Kök `.env.example` dosyasını temel alın; yerel web değerlerini `apps/web/.env.local` içine kaydedin ve gizli değerleri depoya eklemeyin. Web için Supabase URL/publishable anahtarı ve AI için `OPENAI_API_KEY` gerekir. Mobil değerler `--dart-define` ile verilir:

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
- `POST /api/internal/documents/scan-jobs` — tarayıcı iş sahiplenme, `DOCUMENT_SCAN_SECRET`
- `POST /api/internal/documents/scan-result` — ClamAV callback, `DOCUMENT_SCAN_SECRET`

Belge tarayıcı `services/document-scanner` container’ıdır. `/health` public olabilir; `/scan` daima bearer secret ister. Callback hedefi istekten değil yalnız `APP_BASE_URL=https://app.kartvizyon.app` ortam değişkeninden okunur. Production deploy sonrası URL `DOCUMENT_SCAN_SERVICE_URL` olarak Vercel’e eklenir. EICAR test dosyası `blocked`, temiz PDF `clean`, bozuk/erişilemeyen dosya `failed` vermeden yayın kapısı geçmez. Cloud Run komutları `services/document-scanner/README.md` içindedir.

Webhook sırları `INTEGRATION_ENCRYPTION_KEY` ile AES-256-GCM şifrelenir. Bu anahtar 32 rastgele baytın Base64 karşılığı olmalı, secret manager dışında tutulmamalı ve kaybedilmemelidir.

## Mobil doğrulama

```powershell
Set-Location apps/mobile
flutter analyze
flutter test
flutter build apk --debug
```

iOS build/signing Codemagic macOS/Xcode worker’da yapılır. `codemagic.yaml` workflow’ları KartVizyon’a ait `app.kartvizyon.mobile`, `kartvizyon_upload` ve `kartvizyon_app_store` referansları dışında signing kimliği kabul etmez.

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
