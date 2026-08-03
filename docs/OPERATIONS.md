# Operasyon rehberi

## Ortam değişkenleri

Kök `.env.example` dosyasını temel alın; yerel web değerlerini `apps/web/.env.local` içine kaydedin ve gizli değerleri depoya eklemeyin. Web için Supabase URL/publishable anahtarı ve AI için `OPENAI_API_KEY` gerekir. Mobil değerler `--dart-define` ile verilir:

```powershell
flutter run --dart-define=KARTVIZYON_API_URL=https://app.example.com --dart-define=SUPABASE_URL=https://project.supabase.co --dart-define=SUPABASE_ANON_KEY=...
```

## Migration ve sağlık

Migrationları numara sırasıyla uygulayın; her `.up.sql` dosyasının `.down.sql` geri alımı vardır. Production öncesi yedek ve staging provası yapın.

- `GET /api/health`: sürüm, uptime ve veritabanı yapılandırması.
- `GET /api/openapi`: temel API sözleşmesi.
- Yanıtlar `x-request-id` taşır; API çağrıları aynı kimlikle JSON log üretir.
- `429` yanıtı `Retry-After: 60` taşır.

## Production zamanlayıcıları

Ham ses temizliği, belge antivirüs taraması, webhook teslimatı/retry ve KVKK dışa aktarma işleyicisi şu uçlarla zamanlanmalıdır:

- `POST /api/internal/retention/audio` — `CRON_SECRET`
- `POST /api/internal/documents/scan-result` — `DOCUMENT_SCAN_SECRET`
- `POST /api/internal/webhooks/deliver` — `WEBHOOK_WORKER_SECRET`
- `POST /api/internal/privacy/process` — `PRIVACY_WORKER_SECRET`

Webhook sırları `INTEGRATION_ENCRYPTION_KEY` ile AES-256-GCM şifrelenir. Bu anahtar 32 rastgele baytın Base64 karşılığı olmalı, secret manager dışında tutulmamalı ve kaybedilmemelidir.

## Mobil doğrulama

```powershell
Set-Location apps/mobile
flutter analyze
flutter test
flutter build apk --debug
```

iOS build/signing yalnızca macOS ve Xcode ile yapılır.
