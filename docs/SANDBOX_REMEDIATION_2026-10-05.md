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
  Ledger: 35 kayıt, son sürüm `0035`.

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
- Production bağımlılık güvenlik denetimi: 0 vulnerability.
- Tam `npm run check` exit 0: format, 35 migration/rollback çifti, lint,
  typecheck, 117 web + 37 contracts + 263 database + 124 mobil test,
  web build ve istemci sır taraması geçti. Guard'ın 3 testi ayrıca geçti.
- Codemagic `mobile_sandbox` grubundaki dört gerekli değer kaydedildi;
  service-role/webhook sırları bu gruba aktarılmadı.
- Sandbox build başlatıldı: `6ac3b19e7394575b200b4d55`, kaynak commit `76484e8`,
  `codex/sandbox-billing-reconciliation-20261005`; ilk gözlem `queued`.
  Build başlangıcı, IPA/TestFlight teslimatı kanıtı değildir.
- İlk build'in 124 mobil testi, signing ve izolasyon guard'ı geçti; IPA
  `1.0.1 (61)` üretildi. Apple upload 90062/90186 ile reddedildi: yayındaki
  `1.0.1` pre-release train kapalı. Yalnız Sandbox workflow'a
  `--build-name=1.0.2` override eklendi; production workflow/pubspec değişmedi.
- Düzeltme sonrası ikinci build: `6ac3b64d7394575b200b4eda`, kaynak commit
  `d5ab690`; doğru staging-only workflow ve commit arayüzde doğrulandı.
  IPA `1.0.2 (61)` üretildi; Apple upload `UPLOAD SUCCEEDED with no errors`.
  Codemagic finished; Apple processing tamamlandı. Apple build UUID
  `c4e88c41-855a-449f-a1b8-17a1300e2f49`. Mevcut `KartVizyon İç Test`
  internal grubunda 1.0.2 (61) **Testing**; iki mevcut testçiye açık.
  Sandbox/staging uyarılı What to Test metni kaydedildi. Genel build listesinde
  beta review Waiting for Review; iç grubun Testing durumu ayrıca doğrulandı.
  Bu işlem App Store sürüm başvurusu değildir; production sürümü değiştirilmedi.

## Test hesabı ve receipt sınırı

Staging ayrı auth kullanıcılarına sahiptir; production hesabı veya parolası
otomatik kopyalanmaz. Email confirmation açık, Apple/Google OAuth kapalıdır.
Test hesabının parolası kullanıcı tarafından oluşturulmalı; sohbete yazılmamalı.

Kullanıcı tarafından oluşturulan staging test hesabı: `brkohrili@hotmail.com`,
UUID `d9b9a47f-b4bf-4bc6-8a91-5596df284b0c`; kişisel workspace
`3d0567bc-a4ee-40cb-87f2-64dbf0037939`. İlk giriş öncesi subscription NULL;
elle premium verilmedi. Parola ajan tarafından okunmadı veya oluşturulmadı.

Mevcut production App User ID'sinin Sandbox receipt'ini yeni staging UUID'sine
restore etmek RevenueCat TRANSFER olayı üretebilir. Transfer handler, iki
kişisel çalışma alanının da aynı DB'de bulunmasını zorunlu kılar. Production
UUID'si staging'de bulunmadığında bu aktarım 422 ile reddedilir; elle premium
vermek veya sahte subscription eklemek doğru doğrulama değildir. Temiz,
satın alma geçmişi olmayan Apple Sandbox test hesabı ile ilk satın alma;
aynı staging UUID'sinde yeniden açma ve restore testi tercih edilmelidir.
Mevcut receipt kullanılacaksa önce transfer davranışı ayrıca çözülmelidir.

## Kalan cihaz doğrulaması — henüz tamamlanmadı

1. Testçi TestFlight'tan **1.0.2 (61)** yükler ve sürüm ekranını gönderir.
2. Uygulamada `brkohrili@hotmail.com` staging hesabı ve kullanıcının kendisinin
   belirlediği parola ile giriş yapar. Sandbox ibaresi ve Premium ekranı alınır.
3. Satın alma geçmişi olmayan Apple Sandbox hesabı ve receipt kimliği kontrol
   edilir. Production receipt'i yeni staging UUID'sine körlemesine restore edilmez.
4. İlk satın alma sonrası gerçek RevenueCat olayı, webhook teslimatı, staging
   DB hakkı ve cihazdaki ücretli kota birlikte doğrulanır. Tek başına Apple
   başarı mesajı veya TEST webhook 200 sonucu yeterli değildir.
5. Aynı staging hesabında yeniden açma ve restore; ardından renewal,
   cancellation ve expiry ayrı ayrı doğrulanır. Manuel premium verilmez.

Test sunucusunda AI sağlayıcı anahtarları tanımlanmadı; bu teslimatın kapsamı
abonelik erişim eşitlemesidir, tüm AI işlemlerinin E2E doğrulandığı anlamına gelmez.

Mevcut build 60 üzerinde tekrar satın alma sorunu çözmez. Bu belge tam E2E
başarısı değildir. Yeni Sandbox build teslim edilmiştir; cihazdaki satın alma
yaşam döngüsünün sonuçları halen beklenmektedir.
