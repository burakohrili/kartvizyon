# Dış konsol tamamlama rehberi

Bu belge, kodu tamamlanmış ama yalnızca yetkili bir insanın dış konsollarda
tıklayabileceği adımları sıralar. Her adım önceki adımın çıktısına bağlı
olduğu için sırayı bozmayın.

## 1. Google Cloud — ClamAV servisi (Cloud Run)

**Ön koşul:** Google Cloud hesabı, faturalandırma etkin bir proje.

1. console.cloud.google.com → yeni proje: `kartvizyon-prod`.
2. Faturalandırmayı bu projeye bağla.
3. API'leri etkinleştir: Cloud Run API, Artifact Registry API.
4. Artifact Registry'de bir Docker repository oluştur (ör. `europe-west1`, Supabase
   projenle aynı/en yakın bölge — gecikmeyi azaltır).
5. Yerelden veya Cloud Build ile imajı derle ve push et:
   ```powershell
   Set-Location d:/girisimler/kartvizyon/services/document-scanner
   gcloud builds submit --tag europe-west1-docker.pkg.dev/kartvizyon-prod/scanner/document-scanner:latest
   ```
6. Cloud Run'a deploy et (private, kimliksiz erişime kapalı):
   ```powershell
   gcloud run deploy document-scanner `
     --image europe-west1-docker.pkg.dev/kartvizyon-prod/scanner/document-scanner:latest `
     --region europe-west1 `
     --no-allow-unauthenticated `
     --set-env-vars APP_BASE_URL=https://app.kartvizyon.app,DOCUMENT_SCAN_SECRET=<secret>
   ```
7. Servis URL'ini al: `gcloud run services describe document-scanner --region europe-west1 --format="value(status.url)"`.
8. Bu URL'i Vercel'e `DOCUMENT_SCAN_SERVICE_URL` olarak ekle (aşağıdaki Vercel adımına bak).
9. Kabul testi: `services/document-scanner/README.md` içindeki EICAR/temiz dosya/bozuk dosya senaryolarını production URL'ine karşı çalıştır.

## 2. Vercel — production ortam değişkenleri

Aşağıdaki değişkenlerin `app.kartvizyon.app` projesinde (Production scope) girili olduğunu doğrula/ekle:

- `DOCUMENT_SCAN_SERVICE_URL` (adım 1'den)
- `DOCUMENT_SCAN_SECRET`
- `CRON_SECRET`
- `PRIVACY_WORKER_SECRET`, `WEBHOOK_WORKER_SECRET`
- `INTEGRATION_ENCRYPTION_KEY` (32 rastgele bayt, Base64)
- `NEXT_PUBLIC_SENTRY_DSN`, `SENTRY_ORG`, `SENTRY_PROJECT`, `SENTRY_AUTH_TOKEN` (adım 5'ten)
- Supabase URL/anon key, `OPENAI_API_KEY`, Resend API key

Değişkenler girildikten sonra yeni bir production deploy tetikle.

## 3. Codemagic

1. codemagic.io → GitHub hesabıyla giriş, `burakohrili/kartvizyon` reposunu bağla.
2. Team → Code signing identities → Android keystore yükle: `apps/mobile/android/kartvizyon-upload.jks`
   (parola/alias'ı `key.properties` şablonundaki isimlerle eşleştir; dosyayı repoya asla ekleme).
3. Environment variables grubu oluştur (`kartvizyon_upload`): `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`,
   `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SENTRY_DSN`.
4. Apple entegrasyonu: Codemagic → Team integrations → App Store Connect → yeni API key
   (adım 4'te oluşturacağın App Store Connect API anahtarı ile).
5. `codemagic.yaml`'daki workflow adlarının (`kartvizyon_upload`, `kartvizyon_app_store`) env group adlarıyla
   birebir eştiğini doğrula.
6. İlk yapı: Android workflow'unu manuel tetikle, üretilen AAB'yi indir, `apps/mobile/README.md`'deki
   yerel doğrulama adımlarıyla karşılaştır.

## 4. App Store Connect

1. developer.apple.com → Certificates, Identifiers & Profiles → yeni App ID: `app.kartvizyon.mobile`.
   - Capabilities: Push Notifications (varsa), Associated Domains (deep link için).
2. App Store Connect → yeni uygulama kaydı: Bundle ID `app.kartvizyon.mobile`, birincil dil Türkçe.
3. `docs/STORE_LISTING_TR.md` içeriğini kopyala: başlık, alt başlık, açıklama, anahtar kelimeler.
4. Privacy → App Privacy formunu `docs/STORE_RELEASE.md`'deki matrikse göre doldur.
5. TestFlight → dahili test grubu oluştur, reviewer hesabını (aşağıda) ekle.
6. Sürüm notlarına reviewer giriş bilgilerini ve demo veri açıklamasını ekle.

## 5. Google Play Console

1. play.google.com/console → yeni uygulama: `app.kartvizyon.mobile`, Türkçe birincil dil.
2. Play App Signing'i etkinleştir (Codemagic'ten gelen AAB upload-key ile imzalı olacak).
3. İlk AAB'yi **manuel** olarak Internal testing track'ine yükle (Codemagic'in otomasyonu
   yalnızca ilk sürümden sonra çalışır).
4. Data Safety formunu `docs/STORE_RELEASE.md` matriksine göre doldur.
5. Store listing: `docs/STORE_LISTING_TR.md` metinlerini ve ekran görüntülerini ekle.
6. Content rating anketini doldur, hesap silme URL'ini (`https://kartvizyon.app/account-deletion`) gir.

## 6. Sentry

1. sentry.io → yeni organizasyon/proje: `kartvizyon-web` (Next.js) ve `kartvizyon-mobile` (Flutter).
2. Web DSN'i Vercel'e `NEXT_PUBLIC_SENTRY_DSN` olarak ekle; source map yüklemesi için
   `SENTRY_ORG`, `SENTRY_PROJECT`, `SENTRY_AUTH_TOKEN` (Settings → Auth Tokens, `project:releases` scope).
3. Mobil DSN'i Codemagic environment group'a `SENTRY_DSN` olarak ekle.
4. Alerts → yeni kural: 5 dakikada %2 üzeri 5xx, yeni regression, cron/scan/deletion hata event'i.
5. Cron Monitoring: `retention/audio`, `privacy/process`, `webhooks/deliver`, `documents/dispatch`
   zamanlayıcıları için birer monitor tanımla (beklenen periyotlarla, `docs/OPERATIONS.md`'e bak).
6. Uptime Monitoring: `https://app.kartvizyon.app/api/health` için 1 dakikalık kontrol.

## 7. Supabase — production migration

```powershell
Set-Location d:/girisimler/kartvizyon
# Staging'de önce dene, sonra production connection string ile:
npm.cmd run migrate:up -- --to 0019_account_deletion
```

Migration sonrası hesap silme worker'ının uçtan uca testini yap (test kullanıcısı oluştur → silme talebi → cascade
doğrulama). `docs/OPERATIONS.md` → "Hesap silme" bölümündeki kısıtları uygula.

## 8. Resend

1. Domain durumu `pending`den `verified`e geçtiğinde resend.com/domains üzerinden doğrula.
2. Gerçek teslimat testi: Gmail, Outlook, iCloud ve bir kurumsal adrese kayıt/doğrulama/parola sıfırlama
   e-postası gönder; spam klasörünü kontrol et.
3. Bounce/complaint webhook'unu Resend → Webhooks altında `ops@kartvizyon.app`'e (veya izlenen bir uca) bağla.

## 9. Destek gelen kutusu

`support@kartvizyon.app` adresine kullanıcı yanıtlarının ulaşması için Hostinger Email (veya başka bir gelen-posta
servisi) satın alınmalı. Alınana kadar destek adresi `kartvizyonapp@gmail.com` olarak kalacak — bu geçici durum
mağaza incelemesini engellemez, ama gerçek kullanıcı desteği için kalıcı çözülmeli.

## Sıra özeti

1 → 2 (scanner URL olmadan Vercel env tamamlanmaz) → 6 (Sentry DSN'siz alarm kurulamaz) → 3 → 4/5 (paralel) → 7 → 8 → 9.
