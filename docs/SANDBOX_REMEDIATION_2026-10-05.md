# iOS Sandbox erişim eşitlemesi — 5 Ekim 2026

## Doğrulanan durum

- TestFlight 1.0.1 (60) canlı API'ye bağlıdır.
- RevenueCat: 4 Ekim 01.01 Türkiye saati INITIAL_PURCHASE, 5 Ekim 01.01
  RENEWAL; TRY 449, premium aktif, SANDBOX. Gerçek ücret kanıtı değildir.
- Production webhook yalnız Production olaylarını gönderir. Bu doğru güvenlik
  sınırıdır; sırf TestFlight testi için kaldırılmamalıdır.
- Mobil erişim sunucunun `/api/settings/billing` sonucundan belirlenir; mağaza
  CustomerInfo verisi tek başına yazma erişimi açmaz.
- Preview ortamı indirildiğinde Supabase URL/anahtar alanlarında `[SENSITIVE]`
  yer tutucuları bulundu. Preview adresi anonim isteğe Vercel giriş HTML'i
  döndürür; 200 HTTP durumu bu API'nin çalıştığı anlamına gelmez.
- `rfzmdpxnfsvatukkedrg` staging projesi resumed; migration ledger tablosu,
  `reconcile_store_subscription` ve aktif Apple ürün eşlemesi SQL ile doğrulandı.

## Hazırlanan değişiklikler

- Satın alma/restore mesajları hem mağaza hem sunucu sonucuna göre belirlenir.
  Salt okunur erişimde restore başarılı diye bildirilmez.
- Canlı API'ye bağlı Sandbox satın alması açıkça açıklanır; tekrar satın alma
  önerilmez. Sunucu yetkilendirmesi değiştirilmedi.
- Staging yerel kuyruğu ayrı SQLite dosyasında, tokenları ayrı secure storage
  anahtarlarında tutulur. Test giriş/çıkışı canlı tokenları silmez. Eski canlı
  dosyalar taşınmaz veya silinmez.
- `kartvizyon-ios-sandbox` elle başlatılır; yalnız `mobile_sandbox` grubunu
  kullanır. Mevcut production workflow'ları aynı kalır.
- Build öncesi guard staging Supabase referansını, gerçek değerlerin varlığını
  ve production olmayan HTTPS API origin'ini zorunlu kılar.

## Tamamlanan sunucu bağlantısı

- Ayrı Vercel projesi: `kartvizyon-sandbox`; yalnız staging Supabase anahtarları.
- Adres: `https://kartvizyon-sandbox.vercel.app`.
- READY deployment: `dpl_B6zZbcnNPFt8J3kR5bwQmhoCP3YF`.
- `REVENUECAT_ALLOWED_ENVIRONMENT=SANDBOX`; ayrı auth/HMAC sırları.
- RevenueCat Sandbox-only webhook: `whintgr087fe16e80`; HMAC açık.
- Gerçek RevenueCat TEST `740D02A0-5E52-429A-AB5F-8D2C1AECE770` teslimatı:
  HTTP 200, `{"received":true,"test":true}`; erişim hakkı oluşturmaz.
- Anonim health 200, oturumsuz billing 401, yanlış webhook auth 401.
- Production olayı reddi ve reconciliation davranışı 17 yerel webhook testi
  içinde doğrulandı; bu, gerçek cihaz yaşam döngüsü kanıtı değildir.
- 124 mobil test ve 3 Sandbox guard testi geçti; Flutter analyze temiz.

## Kalan cihaz doğrulaması — henüz tamamlanmadı

1. Staging Active durumunu ve migration 0035 / ürün-plan eşlemesini doğrula.
2. Ayrı test sunucusuna yalnız staging Supabase anahtarlarını tanımla.
   `REVENUECAT_ALLOWED_ENVIRONMENT=SANDBOX`; ayrı webhook auth/HMAC kullan.
   Preview korumasını veya production güvenlik sınırını kaldırma.
3. RevenueCat'te Sandbox-only webhook'u test sunucusuna bağla. TEST 200,
   yanlış imza 401, production olayı 202 ve DB değişikliği yok kanıtlarını al.
4. `mobile_sandbox`: KARTVIZYON_SANDBOX_API_URL, SUPABASE_URL,
   SUPABASE_ANON_KEY, REVENUECAT_APPLE_PUBLIC_API_KEY, isteğe bağlı SENTRY_DSN.
   Service-role/webhook sırları mobil gruba konmaz.
5. Kullanıcı açıkça build istediğinde doğrulanmış commit'ten ayrı workflow ile
   TestFlight'a yükle. App Review'a staging sürümü gönderme.
6. Testçi staging'de ayrı hesabıyla giriş yapar. Production kullanıcı UUID'si
   staging'de var kabul edilmez; elle premium verilmez. Aynı Apple receipt'in
   farklı kullanıcıya transfer davranışı değerlendirilmeden restore yaptırma.
7. Satın alma/restore sonrası staging DB hakkı ve cihazdaki kota birlikte
   doğrulanır. Sonra renewal, cancellation ve expiry ayrı ayrı doğrulanır.

Mevcut build 60 üzerinde tekrar satın alma sorunu çözmez. Bu belge tam E2E
başarısı veya yeni TestFlight build'in teslim edildiği iddiası değildir.
