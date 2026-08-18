# Uygulama yol haritası

## Tamamlanan ürün kapsamı

1. **Temel, kimlik ve tenant güvenliği** — Monorepo, geri alınabilir Supabase migrationları, RLS, Supabase SSR kimliği, çalışma alanları, ekip davetleri ve global oturum iptali.
2. **Saha müşteri hafızası** — Müşteri/kişi CRUD, CSV/XLSX içe aktarma/geri alma, duplicate önerileri, kartvizit OCR, harita/geofence ve sürekli GPS kullanmayan gizlilik modeli.
3. **Ziyaret ve AI** — Çevrimdışı taslak/debrief kuyruğu, idempotent senkronizasyon, OpenAI transkripsiyon, Zod doğrulamalı `needs_review` özeti, kullanıcı/yönetici onayı ve onaylı takiplerden görev/hafıza üretimi.
4. **Saha operasyonları** — Takvim, bölge/takım, fırsat, ürün/fiyat listesi, sunucuda hesaplanan sipariş taslakları, yorum, bildirim, belge karantinası ve dinamik formlar.
5. **Raporlama** — Onaylı ziyaretlerden filtreli raporlar, gerçek ana ekran metrikleri, Türkçe PDF/XLSX, süreli ve iptal edilebilir hash-token paylaşımı.
6. **Web ve mobil paritesi** — Next.js PWA, Flutter Android/iOS, canlı müşteri/ziyaret/görev API’leri, kamera, ses, çevrimdışı ziyaret/debrief ve mobil KVKK merkezi.
7. **Ticari ve entegrasyon** — Plan/kota görünümü, hash’li tek-seferlik API anahtarları, HTTPS webhook ve olay kuyruğu, rıza ve veri dışa aktarma/silme talepleri.
8. **Operasyonel güvenlik** — Kullanıcı/rota bazlı hız limiti, güvenlik başlıkları, istek kimliği, JSON HTTP logları, sağlık ve OpenAPI uçları.

9. **Production web yüzeyi** — `kartvizyon.app` pazarlama/SEO sitesi, `app.kartvizyon.app` uygulama yüzeyi; gizlilik, KVKK, koşullar, destek ve hesap silme sayfaları.
10. **Belge tarama kuyruğu** — atomik sahiplenme, 15 dakika stale retry, üç deneme sınırı, imzalı indirme ve ClamAV container/callback akışı.
11. **Mobil yayın temeli** — `app.kartvizyon.mobile` kimlikleri, debug-release engeli ve izole Codemagic AAB/IPA workflow’ları.
12. **Mağaza inceleme yüzeyi** — otomatik onaylı reviewer hesabı, production giriş testi, demo çalışma alanı ve 1024×1024 opak ikon kaynağı.
13. **Hesap silme uygulaması** — kişisel alan silme, kurumsal atıf anonimleştirme, storage temizliği ve organizasyon sahipliği koruması; production migration uygulaması bekliyor.

## Kalite kapısı

- `npm.cmd run check`: biçim, migration/rollback, lint, tip, test, production build ve Flutter kontrolleri.
- Android: `flutter build apk --debug`; production AAB yalnız KartVizyon upload keystore ile.
- iOS binary: Codemagic macOS/Xcode worker, yalnız KartVizyon profile/bundle ID ile.

## Production durumu

Son doğrulama: 18 Ağustos 2026, konsollar canlı okunarak.

### Tamamlandı

- **Web:** `kartvizyon.app` ve `app.kartvizyon.app` yayında; production deployment
  commit `bf20b2a`, `/api/health` veri tabanı, AI ve admin yapılandırmasını doğruluyor.
- **Vercel secret'ları** girili (ClamAV `DOCUMENT_SCAN_SERVICE_URL` dahil); cron uçları
  yetkisiz çağrıda 401 döndürüyor.
- **Codemagic:** Android ve iOS workflow'ları çalışıyor — imzalı AAB (versionCode 13)
  ve IPA (build 12), her ikisi de `bf20b2a` commit'inden.
- **Apple:** uygulama kaydı (Apple ID 6797552440) ve TestFlight'ta 5 build; dahili test
  grubu kurulu, build 11–12 gerçek cihazda çalıştırıldı.
- **Google Play:** versionCode 13 kapalı testte (%100), mağaza girişi "Canlı",
  9 politika beyanı tamamlandı.
- **Ticari model:** ADR-0005 fiyatları, `0021_entitlements` plan tohumları,
  `entitlements.ts` kota uygulaması, 14 gün deneme ve deneme bitiş cron'u.
- **AI maliyeti:** özet Terra, OCR Luna; kullanıcı başı aylık maliyet 64 ₺ → 34 ₺.
- **iyzico site koşulları:** mesafeli satış, teslim/iptal/iade, fatura süreci ve
  ödeme öncesi bilgilendirme bileşeni hazır.
- **Kalite kapısı:** `npm run check` yerelde tam yeşil (CRLF sorunu `.gitattributes`
  ile giderildi).

### Kalan

- App Store Connect alan girişleri ve iPhone 6.5" ekran görüntüleri
  (`docs/APPLE_SUBMISSION_CHECKLIST.md`).
- Play içerik derecelendirme anketi ve üretim erişimi için 12 test kullanıcısı × 14 gün.
- Supabase `0019`, `0020`, `0021` migration'larının production'a uygulanması ve
  Free → Pro geçişi.
- Sentry projesi/DSN ve alarmlar; Resend domain doğrulaması ve teslimat testi.
- iyzico sandbox, checkout ve webhook (kullanıcı kararıyla en sona bırakıldı).
- Mobil IAP (ADR-0004 Faz C); Play abonelik ürünü için AAB'ye ödeme kütüphanesi gerekiyor.
- Kullanıcıdan alınacak bilgiler: telefon, KEP, meslek odası, vergi levhası, IBAN.

## Bilinçli kapsam dışı

Canlı stok, cari hesap, tahsilat, e-fatura, irsaliye, sürekli GPS, karmaşık rota optimizasyonu ve müşteri görüşmesi kaydı.
