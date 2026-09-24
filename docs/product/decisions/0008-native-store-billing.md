# ADR-0008 — Yerel mağaza aboneliği ve tek entitlement kaynağı

Durum: Kabul edildi · 12 Eylül 2026

## Karar

- Kişisel çalışma alanı Bireysel planı iOS'ta App Store, Android'de Google Play
  üzerinden satın alır. Uygulama içinden harici checkout bağlantısı verilmez.
- RevenueCat mağaza SDK'larını normalize eder; ödeme ekranı ve tahsilat yine
  Apple/Google tarafından yürütülür.
- RevenueCat `app_user_id`, Supabase kullanıcı UUID'sidir. Rastgele/e-posta
  kimliği kullanılmaz.
- Hakların sunucu doğruluk kaynağı `workspace_subscriptions` tablosudur. Mobil
  `CustomerInfo` yalnız anlık kullanıcı geri bildirimi verir; premium API'ler
  webhook doğrulanmadan açılmaz.
- Webhook hem sabit Authorization başlığı hem HMAC-SHA256 imzası ve 5 dakikalık
  zaman penceresiyle doğrulanır. Olay kimliği idempotenttir; eski olay yeni
  abonelik durumunu geriye alamaz.
- Kurumsal çalışma alanında mobil satın alma gösterilmez; plan kurum yöneticisi
  tarafından web/teklif kanalıyla yönetilir.

## Ürün kimlikleri

| Mağaza | Ürün                                      | Dönem |
| ------ | ----------------------------------------- | ----- |
| Apple  | `app.kartvizyon.mobile.premium.monthly`   | Aylık |
| Google | `premium_individual`, base plan `monthly` | Aylık |

RevenueCat entitlement kimliği `premium`, current offering yalnız aylık ürünü
içermelidir. İlk taslaktaki yıllık ürün kimlikleri `0027` ile pasifleştirilmiştir.

## Önceki kararlarla ilişki

ADR-0004'ün “mobilde satın alma yüzeyi yok” geçici dağıtım kuralı bu kararla
değiştirilmiştir. Harici web ödemesine yönlendirmeme, kurumsal/bireysel ayrımı
ve server-side entitlement ilkeleri aynen korunur.
