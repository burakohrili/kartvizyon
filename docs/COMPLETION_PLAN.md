# Tamamlama planı

Son doğrulama: 18 Ağustos 2026 — konsollar (App Store Connect, Play Console,
Codemagic, Vercel) canlı olarak okunarak güncellendi.

Ürün kodu, CI ve her iki mağaza pipeline'ı hazırdır. Kalan iş **mağaza veri
girişi, Play test kullanıcısı süresi ve ödeme entegrasyonudur.**

## Tamamlanan

| #   | İş                                                       | Kanıt                                                               |
| --- | -------------------------------------------------------- | ------------------------------------------------------------------- |
| ✅  | Vercel production deploy                                 | commit `bf20b2a` yayında, `/api/health` sağlıklı                    |
| ✅  | Codemagic Android + iOS workflow                         | AAB #7 (versionCode 13), IPA #6 (build 12)                          |
| ✅  | TestFlight yükleme ve dahili test                        | 5 build; build 11–12 gerçek cihazda çalıştırıldı                    |
| ✅  | Play kapalı test (Alpha) yayını                          | versionCode 13, %100 kullanıma sunum                                |
| ✅  | Play mağaza girişi                                       | "Canlı"; simge, özellik grafiği, telefon + tablet görselleri        |
| ✅  | Play politika beyanları                                  | 9 beyan tamamlandı (Veri güvenliği, gizlilik, oturum bilgisi dahil) |
| ✅  | Vercel production secret'ları                            | ClamAV servis URL'i dahil girili                                    |
| ✅  | Fiyat kararı ve plan limitleri                           | ADR-0005 + `0021_entitlements`                                      |
| ✅  | Kota uygulaması (müşteri, AI dakika, OCR, koltuk)        | `apps/web/src/lib/entitlements.ts` + 10 test                        |
| ✅  | AI maliyet optimizasyonu                                 | Kullanıcı başı 64 ₺ → 34 ₺                                          |
| ✅  | iyzico site koşulları (sözleşme, iade, ön bilgilendirme) | `docs/BILLING_INVOICE_PROCESS.md`                                   |
| ✅  | `npm run check` yerel kapısı                             | `.gitattributes` + prettier `endOfLine: auto`                       |

## Kullanıcıda olan işler

| #   | İş                                    | Not                                                              |
| --- | ------------------------------------- | ---------------------------------------------------------------- |
| U.1 | iPhone 6.5" ekran görüntüleri         | En az 3 adet; iPad artık gerekmiyor (cihaz ailesi yalnız iPhone) |
| U.2 | Play için 12 test kullanıcısı, 14 gün | Şu an 1 kayıtlı; üretim erişiminin tek engeli                    |
| U.3 | Telefon, KEP, meslek odası bilgisi    | iyzico başvurusu ve site iletişim alanı için                     |
| U.4 | Vergi levhası, imza sirküleri, IBAN   | iyzico başvuru evrakı                                            |
| U.5 | Supabase Pro'ya geçiş                 | Free planda proje duraklıyor ve otomatik yedek yok               |
| U.6 | OpenAI aylık $50 hard limit           | ADR-0005 bütçe kapısı                                            |

## Kalan iş

| #   | İş                                             | Bağımlılık | Rehber                                 |
| --- | ---------------------------------------------- | ---------- | -------------------------------------- |
| 1.1 | App Store Connect alan girişleri               | U.1        | `docs/APPLE_SUBMISSION_CHECKLIST.md`   |
| 1.2 | Play içerik derecelendirme anketi              | —          | Play Console → Uygulama içeriği        |
| 1.3 | Supabase `0019`, `0020`, `0021` migration'ları | U.5        | `docs/OPERATIONS.md`                   |
| 1.4 | Sentry projesi, DSN ve alarmlar                | —          | `docs/EXTERNAL_SETUP_RUNBOOK.md` §6    |
| 1.5 | Resend domain doğrulaması ve teslimat testi    | —          | `docs/EXTERNAL_SETUP_RUNBOOK.md` §8    |
| 2.1 | iyzico sandbox, ürün/plan tanımı               | U.3, U.4   | `docs/IYZICO_APPLICATION_READINESS.md` |
| 2.2 | Web checkout ekranı                            | 2.1        | `PrePurchaseDisclosure` bağlanır       |
| 2.3 | `POST /api/internal/webhooks/iyzico`           | 2.1        | Mevcut webhook deseni                  |
| 2.4 | Plan yükseltme / koltuk / iptal ekranları      | 2.2        | —                                      |
| 2.5 | AI ek paketi satın alma akışı                  | 2.3        | `workspace_ai_topups`                  |
| 3.1 | Mobil IAP (ADR-0004 Faz C)                     | 2.x        | AAB'ye Play Billing eklenmeli          |

## Ürün doğrulama (yayınla paralel)

- 15 saha çalışanı + 5 satış müdürü görüşmesi
- 3 şirket pilotu
- AI özet/transkript doğruluk ölçümü ve `needs_review` onay oranı takibi
- Destek gelen kutusu: `support@kartvizyon.app` mailbox'ı
