# Tamamlama planı

Bu belge, yayına kadar kalan işleri bağımlılık sırasına göre listeler. Kod tarafındaki
ürün kapsamı büyük ölçüde bitmiştir; kalan işler dış hesap kurulumu, ödeme ürünü ve
mağaza gönderimidir.

## Faz 0 — Şu an bloke olmayan, hemen yapılabilir

| # | İş | Sahip | Not |
|---|-----|-------|-----|
| 0.1 | Vercel production deploy | Kullanıcı | Son kod henüz production'a çıkmadı; DNS zaten doğru |
| 0.2 | Supabase `0019_account_deletion` migration | Kullanıcı | Önce staging provası, sonra production |
| 0.3 | Resend domain doğrulaması ve teslimat testi | Kullanıcı | Domain `pending` durumundan çıkınca |

## Faz 1 — Dış konsollar

Adım adım komutlar ve tıklama sırası için `docs/EXTERNAL_SETUP_RUNBOOK.md`.

| # | İş | Bağımlılık |
|---|-----|-----------|
| 1.1 | Google Cloud: Cloud Run + Artifact Registry, ClamAV deploy | Faturalandırma etkin proje |
| 1.2 | Vercel: `DOCUMENT_SCAN_SERVICE_URL` ve diğer secret'lar | 1.1 |
| 1.3 | Sentry: web/mobil proje, DSN, 5xx + cron + uptime alarmları | — |
| 1.4 | Codemagic: repo bağlama, keystore yükleme, Apple entegrasyonu | Apple hesabı |
| 1.5 | App Store Connect: App ID + uygulama kaydı | Apple Developer Program üyeliği |
| 1.6 | Play Console: uygulama kaydı, ilk AAB manuel internal track | Play Developer hesabı |

**Açman gereken hesaplar:** Google Cloud (faturalandırma), Codemagic, Apple Developer
Program (yıllık $99), Google Play Console (tek seferlik $25), Sentry.

## Faz 2 — Ödeme ürünü (ADR-0003)

Karar verildi: iyzico Subscription, TRY, aylık/yıllık; bireysel + kurumsal birlikte;
satın alma yalnız web; mobilde satın alma yok. Gerekçe:
`docs/product/decisions/0003-commerce-and-store-distribution.md`.

| # | İş |
|---|-----|
| 2.1 | iyzico sandbox hesabı, ürün ve plan tanımları |
| 2.2 | `subscriptions` / `entitlements` migration + rollback |
| 2.3 | Plan limiti kontrolü (koltuk, AI kotası, dosya) mevcut billing yüzeyine bağlanır |
| 2.4 | iyzico webhook ucu: imza doğrulama, idempotent işleme, audit kaydı |
| 2.5 | Web checkout, plan yükseltme ve iptal ekranları |
| 2.6 | Fatura ve iade süreci (Türkiye mevzuatı, Noesis Social bilgileri) |
| 2.7 | Mobil `settings/billing` salt-okunurluğunun testle sabitlenmesi |
| 2.8 | Sandbox → production geçişi ve gerçek kart testi |

## Faz 3 — Mağaza gönderimi

| # | İş | Bağımlılık |
|---|-----|-----------|
| 3.1 | Ekran görüntüleri (telefon + tablet, iOS + Android) | 1.4 çıktısı build |
| 3.2 | Play feature graphic (1024×500) | Logo hazır |
| 3.3 | App Privacy / Data Safety formlarının konsolda gönderimi | 1.5, 1.6 |
| 3.4 | Content rating, export compliance, destek/gizlilik URL'leri | 0.1 (siteler canlı olmalı) |
| 3.5 | Reviewer hesabı bilgilerinin inceleme alanlarına girilmesi | — |
| 3.6 | Gerçek cihazda signed build testi (iOS TestFlight + Android internal) | 1.4 |
| 3.7 | Kademeli production yayını | Tümü |

## Faz 4 — Ürün doğrulama (yayınla paralel)

- 15 saha çalışanı + 5 satış müdürü görüşmesi
- 3 şirket pilotu
- AI özet/transkript doğruluk ölçümü ve `needs_review` onay oranı takibi
- Destek gelen kutusu: `support@kartvizyon.app` için Hostinger Email veya eşdeğeri

## Bu turda kapatılanlar

- ✅ Gradle/Java/Android build hatası — `org.gradle.java.home` ile JDK 21 sabitlendi;
  `flutter build apk --debug`, `flutter analyze` ve 5 mobil test geçiyor.
- ✅ Marka logosu web (favicon, apple-icon, PWA manifest, sidebar, pazarlama başlığı),
  Android mipmap ve iOS AppIcon setlerine uygulandı.
- ✅ Pazarlama sitesine 8 özellik kartı (nasıl çalışır / ne işe yarar), 3 katmanlı
  fiyatlandırma bölümü ve FAQPage JSON-LD işaretli 7 soruluk SSS eklendi.
- ✅ Ödeme mimarisi ADR-0003 olarak kalıcılaştırıldı.
- ✅ Dış konsol adımları `docs/EXTERNAL_SETUP_RUNBOOK.md` olarak yazıldı.
