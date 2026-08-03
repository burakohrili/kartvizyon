# KartVizyon AI

Saha ekiplerinin ziyaret sonrası anlattıklarını onaylı kurumsal hafızaya dönüştüren, sonraki ziyaret öncesinde kısa brifing sunan mobil + web platformu.

## Başlangıç

```powershell
npm.cmd install
Copy-Item .env.example .env.local
npm.cmd run dev
```

Web uygulaması `http://localhost:3000` adresinde açılır. Production public site `https://kartvizyon.app`, authenticated uygulama `https://app.kartvizyon.app` adresindedir.

Supabase kimlik ve veri akışını etkinleştirmek için `.env.local` içine proje URL'si ile anon anahtarını ekleyin, ardından `packages/database/migrations` altındaki `.up.sql` dosyalarını sırayla uygulayın. Anahtarlar yoksa arayüz güvenli demo verileriyle çalışır.

## Depo yapısı

- `apps/web`: Next.js public pazarlama/legal sitesi, yönetim paneli ve saha web API deneyimi
- `apps/mobile`: Flutter Android/iOS saha uygulaması ve çevrimdışı Drift kuyruğu
- `services/document-scanner`: ayrı deploy edilen ClamAV belge tarayıcı container’ı
- `packages/contracts`: durum makineleri, roller ve doğrulanan domain sözleşmeleri
- `packages/database`: PostgreSQL/Supabase migration, rollback ve RLS testleri
- `docs`: mimari kararlar, yol haritası ve ürün sınırları

## Kalite kapısı

```powershell
npm.cmd run check
```

Bu komut migration/rollback eşlerini de doğrular. Operasyon, yayın ve güvenlik ayrıntıları için `docs/OPERATIONS.md`, `docs/SECURITY.md` ve güncel `docs/ROADMAP.md` dosyalarına bakın.

## Mobil uygulama

```powershell
Set-Location apps/mobile
flutter pub get
dart run build_runner build
flutter run
```

`npm.cmd run check` web, sözleşme, veritabanı ve Flutter analyze/test kapılarını birlikte çalıştırır.

## Production yayın

- Güncel durum ve kalan dış hesap adımları: `docs/ROADMAP.md`
- Operasyon/cron/ClamAV/incident runbook: `docs/OPERATIONS.md`
- Mobil tasarım sistemi: `docs/DESIGN.md`
- Codemagic, signing, App Store ve Play Console kapısı: `docs/STORE_RELEASE.md`
- Türkçe App Store/Google Play metinleri ve ekran görüntüsü planı: `docs/STORE_LISTING_TR.md`
- Production servis kararı: `docs/product/decisions/0002-production-services.md`

Ödeme sağlayıcısı bilinçli olarak bağlı değildir. Ürün hem bireysel hem kurumsal satılacaktır; web tahsilatı ve mağaza içi abonelik modeli ayrı karar sonrasında uygulanacaktır.
