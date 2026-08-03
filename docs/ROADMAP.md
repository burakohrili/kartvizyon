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

### Tamamlandı

- Supabase production projesi ve 18 uygulanmış migration; Auth redirect URL’leri. 19. migration yerelde hazır ve güvenlik denetimi nedeniyle production uygulaması bekliyor.
- Hostinger DNS: root Vercel, `app` Vercel CNAME, Resend DKIM/SPF/MX/DMARC.
- Resend sending-only API key, Supabase custom SMTP, Türkçe markalı Auth şablonları ve güvenlik bildirimleri.
- Vercel root ve `app` domain doğrulaması; web production build ve public mağaza URL’leri.
- ClamAV servis kodu, production tarama migration’ı, callback/cron ve retry mimarisi.
- Mobil production kimliği, deep link, release signing güvenlik kapısı, KartVizyon'a özel Android upload keystore'u ve Codemagic yapılandırması.
- Reviewer production hesabı ve demo verisi; web giriş/panel akışı doğrulandı.
- Sentry Next.js ve Flutter SDK entegrasyonu; DSN/proje/alarm oluşturma bekliyor.
- Modern mobil kapsül navigasyon, hareket azaltma desteği ve güncel tasarım tokenları.

### Dış hesap/son doğrulama bekliyor

- Resend domain durumu DNS doğru olmasına rağmen sağlayıcıda `pending`; gönderim testi doğrulama sonrası.
- ClamAV container’ın Cloud Run’a deploy’u ve `DOCUMENT_SCAN_SERVICE_URL` Vercel secret’ı.
- Sentry hesabı henüz oluşmadı; kullanıcı onayı sonrası projeler/DSN ve 5xx/cron alarm hedefi.
- Codemagic hesabına repo ve üretilmiş KartVizyon keystore'unun yüklenmesi; App Store API key ve provisioning profile eklenmesi.
- App Store Connect/Play Console listing, Data Safety/App Privacy formlarının konsolda gönderimi, ekran görüntüleri ve signed gerçek cihaz testleri.
- `0019_account_deletion` migration'ının Supabase'e uygulanması ve worker'ın production uçtan uca testi.
- 15 saha çalışanı + 5 satış müdürü görüşmesi, 3 şirket pilotu ve gerçek veri doğruluk ölçümleri.

### Bilinçli olarak en son

- Hem bireysel hem kurumsal satış yapılacaktır. Web tahsilatı, App Store/Play billing, vergi/fatura, entitlement ve iade modeli birlikte kararlaştırılmadan ödeme sağlayıcısı bağlanmaz.

## Bilinçli kapsam dışı

Canlı stok, cari hesap, tahsilat, e-fatura, irsaliye, sürekli GPS, karmaşık rota optimizasyonu ve müşteri görüşmesi kaydı.
