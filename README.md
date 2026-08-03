# KartVizyon AI

Saha ekiplerinin ziyaret sonrası anlattıklarını onaylı kurumsal hafızaya dönüştüren, sonraki ziyaret öncesinde kısa brifing sunan mobil + web platformu.

## Başlangıç

```powershell
npm.cmd install
Copy-Item .env.example .env.local
npm.cmd run dev
```

Web uygulaması `http://localhost:3000` adresinde açılır.

Supabase kimlik ve veri akışını etkinleştirmek için `.env.local` içine proje URL'si ile anon anahtarını ekleyin, ardından `packages/database/migrations` altındaki `.up.sql` dosyalarını sırayla uygulayın. Anahtarlar yoksa arayüz güvenli demo verileriyle çalışır.

## Depo yapısı

- `apps/web`: Next.js yönetim paneli ve saha web deneyimi
- `apps/mobile`: Flutter Android/iOS saha uygulaması ve çevrimdışı Drift kuyruğu
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
