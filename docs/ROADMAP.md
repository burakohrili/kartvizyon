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

## Kalite kapısı

- `npm.cmd run check`: biçim, migration/rollback, lint, tip, test, production build ve Flutter kontrolleri.
- Android: `flutter build apk --debug`.
- iOS binary üretimi macOS/Xcode gerektirir.

## Dış yetki veya altyapı gerektiren yayın adımları

Kod tarafı hazırdır; aşağıdakiler hesap, bütçe veya production yetkisi gerektirir:

- Supabase production projesine 17 migrationı uygulamak; Auth e-posta sağlayıcısı ve redirect URL’lerini açmak.
- Obje depolama kovalarını ve dosya tarama servisini bağlamak; saklama cron secret’ını tanımlamak.
- Ödeme sağlayıcısı abonelik webhooklarını, webhook teslimat worker/retry zamanlayıcısını bağlamak.
- Harita sağlayıcısı, alan adı, hosting, hata izleme ve operasyon alarmlarını açmak.
- Apple/Google geliştirici hesapları, signing sertifikaları ve mağaza yayınları.
- 15 saha çalışanı + 5 satış müdürü görüşmesi, 3 şirket pilotu ve gerçek veri doğruluk ölçümleri.

## Bilinçli kapsam dışı

Canlı stok, cari hesap, tahsilat, e-fatura, irsaliye, sürekli GPS, karmaşık rota optimizasyonu ve müşteri görüşmesi kaydı.
