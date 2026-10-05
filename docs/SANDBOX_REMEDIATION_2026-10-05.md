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

### Mevcut receipt için sunucu doğrulaması — 5 Ekim 18:27 TR

Kullanıcı salt-okunur RevenueCat v2 sunucu anahtarını açıkça onayladı.
`KartVizyon Sandbox Readonly Reconciliation`: Customers ve Subscriptions
Read only; diğer tüm izinler No access. Anahtar yalnız ayrı Vercel
`kartvizyon-sandbox` projesinde `REVENUECAT_SANDBOX_READ_API_KEY` Secret
olarak saklandı; mobil/Codemagic/Git/sohbete aktarılmadı.

`sandbox-reconciliation.ts` yalnız tam staging URL + SANDBOX ortamı + yukarıdaki
tek test UUID'sinde çalışır. Authenticated billing GET, kişisel workspace'in
sahibini bağımsız doğrular. Güncel RevenueCat sahibi, Apple mağazası, Sandbox
ortamı, katalog ürünü ve Premium entitlement birlikte doğrulanır. En son Apple
transaction ID'si original transaction ID yerine kullanılmaz: gerçek v2
customer-event kaydındaki `original_transaction_id` gerekir. V2 `app_id`,
gerçek API yanıtında body dışında envelope'dadır; ayrı doğrulanır. Tarihsel
kanıt okunduktan sonra güncel sahiplik tekrar okunur. Eksik kanıt veya API
hatasında hak verilmez. Sonuç mevcut service-role-only atomic RPC ve
`SANDBOX_SERVER_SNAPSHOT` audit türüyle yazılır; Apple olayı taklit edilmez.

Yalnız bu test kullanıcısına gelen Sandbox TRANSFER için store/environment
opsiyonel olabilir; güncel sunucu doğrulaması zorunludur. Eski production
UUID'sinin staging'de auth hesabı bulunması artık bu dar recovery için
gerekmiyor. Diğer transferler ve production koruması değiştirilmedi. Receipt'i
RevenueCat'te başka hesaba geçirmek için yine cihazdaki gerçek restore gerekir;
sunucu anahtarı transfer/satın alma/iptal yetkisine sahip değildir.

Sandbox deployment `dpl_DayJYSgZQerBnmUQ1dzPjvDHKKqV` READY, kaynak
`57f9dc9`; stable alias `https://kartvizyon-sandbox.vercel.app`. İmzalı gerçek
TEST `EF694625-B72D-499C-B43B-D79EE4ED7146` HTTP 200:
`connected=true`, `sourceSubscriptionRecognized=true`,
`sourcePurchaseProofVerified=true`, `targetSubscriptions=0`. Bu yalnız gerçek
okuma bağlantısı ve eski receipt kanıtını doğrular; test Premium vermez.
Kanıt: `artifacts/app-store-review/sandbox-readonly-verification-2026-10-05.png`.
Health 200, oturumsuz billing 401, imzasız webhook 401. Yeni mobil build
gerekmez; mevcut Sandbox 1.0.2 (61) aynı authenticated billing GET'i kullanır.

144 web testi (24 recovery + 20 webhook dahil), lint, typecheck, web build ve
istemci sır taraması geçti. Production dependency audit 0; tüm dependency
audit'inde 9 geliştirme bağımlılığı uyarısı var (2 moderate, 7 high); bu task'ta
bağımlılık sürümleri değiştirilmedi. Bunlar yok sayılıp “tüm audit temiz” denmez.

Testçinin staging uygulama hesabı `brkohrili@hotmail.com`, Apple satın alma
hesabı `v.yeter@icloud.com` ve ülke Türkiye; iki hesabın e-postasının aynı
olması gerekmez. Yeni satın alma yerine **Satın almaları geri yükle** bir kez
istenmiştir. Restore sonrası RC sahiplik, staging DB ücretli kota ve cihaz
ekranı henüz birlikte doğrulanmadı. Yenileme/iptal/expiry döngüsü de tamamlandı
diye raporlanamaz. Manuel lifetime Premium halen geri açılmadı.

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
