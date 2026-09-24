# KartVizyon build öncesi inceleme — 24 Eylül 2026

**Karar: ENGELLİ. Yeni ödeme yapısıyla release build / mağaza gönderimine hazır değil.**

İnceleme 23 Eylül'de başladı, 24 Eylül'de devam etti. Başlangıç HEAD: `93d416d911e52ceccbb876112eb4fe5dbf39ec72`. Sonuçlar bu commit üzerindeki geniş, commit edilmemiş çalışma ağacına aittir. Bu çalışmada release build, deploy, commit, push, mağaza işlemi veya production veri değişikliği yapılmadı.

## Uzman rolü ve kaynaklar

Çalışma rolü: KartVizyon ürün/mimari, Flutter/Next.js, Supabase/PostgreSQL yetkilendirme ve abonelik release QA sorumlusu. Testlerden önce [uzman çalışma promptu](PRE_BUILD_EXPERT_PROMPT.md) yazıldı.

Erişilebilir sohbetlerin ilgili ve son bölümleri okundu; bütün geçmişin eksiksiz incelendiği iddia edilmiyor:

- **Release E2E güvenlik doğrulaması:** önceki staging scanner/tenant/privacy testleri, `0034` migration, ardından mağaza/RevenueCat kurulumu. Önceki çalışmada staging testlerinin geçtiği raporlanmış; bu oturumda tekrar çalıştırılmadı.
- **Abonelik kurulumunu kontrol et:** müşteri yaşam döngüsü, şirket kimliği, Field Mode, bildirim, fırsat, sipariş ve release cleanup görevleri.
- **Araştırma raporu hazırla:** son ürün kararı 14 gün kartsız deneme, 60 deneme AI özeti, ücretli ayda 125 AI özeti, standart 449 TL; build en son.
- **KartVizyon AI’ı hayata geçir**, **Tamamla KartVizyon AI gönderimi**, **Kartvizyon Uygulama Fikri:** ürün ve geçmiş yayın bağlamı. Eski işlemler veya onaylar bu incelemede yeniden uygulanmadı.

Geçmiş sohbet Google aylık ürününün RevenueCat'e bağlandığını bildiriyor. Son Apple mesajı uygulamanın oluşturulduğunu söylüyor; tamamlanmış Apple ürün/offering/webhook/sandbox yaşam döngüsü kanıtı yok. Bunlar güncel konsol doğrulaması değildir.

## Uygulama yapısı ve özellikler

| Katman                      | Görev                                                                  | İncelemede görülen sınır                                                     |
| --------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `apps/mobile`               | Flutter Android/iOS; saha ekranları, izinler, RevenueCat, Drift kuyruk | Fiziksel cihaz/satın alma E2E yerel testle kanıtlanamaz                      |
| `apps/web`                  | Next.js pazarlama/legal, yönetim paneli, web ve mobil API              | Canlı sürüm yerel çalışma ağacındaki yeni ödeme sürümünden farklı davranıyor |
| `packages/contracts`        | Zod sözleşmeleri, roller, durum makineleri                             | Sözleşme testleri gerçek RLS yerine geçmez                                   |
| `packages/database`         | Supabase/PostgreSQL, RLS, RPC, 34 migration/rollback çifti             | Ödeme SQL'inde mevcut testlerin yakalamadığı davranış hataları bulundu       |
| `services/document-scanner` | Ayrı ClamAV tarama ve callback servisi                                 | Üç yerel test geçti; gerçek tarama E2E önceki sohbet kanıtı                  |

| Özellik                 | Bireysel                                       | Ekip/kurumsal                          | Web / mobil ve test sınırı                                                      |
| ----------------------- | ---------------------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------- |
| Kimlik ve çalışma alanı | Kişisel alan, şirket kimliği                   | Organizasyon, bölge/takım, üyelik      | API workspace/RLS sınırı; tüm canlı rol kombinasyonları yeniden sınanmadı       |
| Müşteri ve kartvizit    | Firma/kişi, OCR, düzenleme, arşiv              | Ortak müşteri hafızası ve yetkiler     | Web+mobil; müşteri yaşam döngüsü ve OCR sözleşme testleri mevcut                |
| Ziyaret ve AI           | Planlama, manuel/sesli not, inceleme/onay      | Yönetici onayı ve kurumsal hafıza      | AI `needs_review`; onaysız veri kurumsal sonuç sayılmaz                         |
| Offline                 | Ziyaret/debrief kuyruğu, yeniden deneme        | Aktif kullanıcı/workspace kapsamı      | Tüm modüller offline değildir; görev offline açığı eski hata kaydında açık      |
| Görev/takvim/bildirim   | Kişisel takip, yerel hatırlatma                | Atanan kullanıcıya görünürlük          | Uygulama açılmadan oluşan web değişikliği için remote push teslimi eksik        |
| Harita/Saha Modu        | Mesafe, kullanıcı başlatmalı görünür saha modu | Workspace kapsamlı adaylar             | Saha modu mobil; 8 saat ve 21.00 sınırı; fiziksel arka plan QA bekliyor         |
| Fırsat/sipariş          | Fırsat ve sipariş taslağı                      | Rol kontrollü onay/red                 | ERP/gerçek stok/fatura/tahsilat değildir                                        |
| Form/belge/aktivite     | Form, fotoğraf/belge, geçmiş                   | Şablon ve ortak akışlar                | Belge temiz olmadan indirme kapısı; gerçek ClamAV tekrar sınanmadı              |
| Rapor/entegrasyon       | Rapor özeti, veri hakları                      | Yönetici raporu, paylaşım, API/webhook | Geniş yönetim ve dışa aktarma yüzeyleri web ağırlıklı                           |
| Abonelik                | Apple/Google aylık satın alma ve restore       | Web/teklif ve yönetici planı           | Mobil kurumsal alanda IAP gösterilmiyor; gerçek web tahsilatı tamamlanmış değil |
| Gizlilik                | Dışa aktarma, hesap silme                      | Üyelik/sahiplik ve anonimleştirme      | Abonelik sonrasında okuma/veri hakları korunmalı                                |

Rol sözleşmesi: `owner`, `sales_director`, `regional_manager`, `team_lead`, `field_sales`, `report_viewer`, `integration_manager`. Plan satın almak bu rol kontrollerinin yerine geçmez.

## Yeni ödeme modeli

| Plan     | Fiyat/dönem                                                 | OCR              | Ses                  | AI özeti                     | Erişim                   |
| -------- | ----------------------------------------------------------- | ---------------- | -------------------- | ---------------------------- | ------------------------ |
| Deneme   | 14 gün, kart yok, otomatik tahsilat yok                     | Toplam 60        | Toplam 120 dk        | Toplam 60                    | Deneme sonunda read-only |
| Bireysel | 449 TL/ay standart, KDV dahil; gerçek mağaza fiyatı SDK'dan | Ayda 125         | Ayda 240 dk          | Ayda 125                     | Kişisel alan             |
| Ekip     | Kaynakta 279 TL/koltuk/ay, en az 3; yıllık 2790             | Koltuk başına 80 | Koltuk başına 150 dk | SQL varsayılanı 125 × koltuk | Havuzlanmış kota         |
| Kurumsal | Kaynakta 449 TL/koltuk/ay, en az 10                         | Sınırsız         | Koltuk başına 250 dk | SQL varsayılanı 125 × koltuk | Organizasyon             |

Ekip/kurumsal fiyatlar kaynak kod ve SQL katalog değerleridir; canlı sözleşme/mağaza teyidi değildir. Ekip kartındaki “Bireysel plandaki her şey” metni, yeni bireysel 240 dk/125 OCR kotasına rağmen ekipte 150 dk/80 OCR bulunması nedeniyle açıklığa kavuşturulmalı. Ekip AI özeti limiti SQL'de var, public plan kartında açıkça gösterilmiyor.

## Doğrulanan ödeme hataları

İzole PGlite (PostgreSQL) denetimi, gerçek `0026` migration'ını ve `0027` entitlement fonksiyonlarını çalıştırır; önkoşul tabloları minimal fixture'dır. Production'a bağlanmaz. Tüm migration zinciri, PostgREST/RLS veya eşzamanlı ağ isteği E2E testi değildir.

Komut: `node artifacts/prebuild-2026-09-23/billing-behavior-audit.mjs`

Sonuç: **10 kontrol; 5 PASS, 5 FAIL; 0 altyapı hatası. Çıkış kodu 1.** Bulgular düzeltilmeden bu denetimin yeşil olması beklenmez.

| Öncelik | Bulgu ve tekrar üretim                                                                           | Etki                                                          | Düzeltme gereksinimi                                                                        |
| ------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| P1      | Gerçek abonelikten sonra aynı workspace'e SANDBOX olayı uygula; 25 günlük hak 5 dakikaya düşüyor | Test ödemesi gerçek erişimi değiştirebiliyor                  | Ortam bazında izolasyon ve endpoint ortam politikası; production haklarını sandbox'tan ayır |
| P1      | Aynı original transaction'ı ikinci kişisel alan sahibine eşle; iki alan da ücretli kalıyor       | Tek satın alma iki hesapta hak bırakıyor                      | Transferi yasaklayan açık politika veya önceki alanı atomik uzlaştıran transfer akışı       |
| P1      | Yeni satın alma sonrası farklı original transaction'ın daha eski expiry olayını gönder           | Yeni ücretli alan read-only oluyor                            | Tek işlem zinciri yerine workspace'teki geçerli satın almaların tamamından hak hesapla      |
| P1      | Ödenmiş dönem bitmeden `SUBSCRIPTION_PAUSED → past_due` uygula                                   | Gelecekte duraklatılacak abonelik hemen kapanıyor             | Planlanan pause ile expiry ayrımı; dönem sonuna kadar erişimi koru                          |
| P1      | Ödenmiş dönem bitmeden `BILLING_ISSUE → past_due` uygula                                         | Tahsilat sorunu hemen erişim kesiyor; grace verisi işlenmiyor | Expiry/grace alanları ve gerçek mağaza durumu ile karar ver                                 |

Kod noktaları:

- [Ödeme SQL — olay sırası, ortam, sahiplik ve workspace upsert](../packages/database/migrations/0026_native_store_billing.up.sql), özellikle 123–180.
- [Entitlement — yalnız active/cancelled kabulü](../packages/database/migrations/0027_trial_subscription.up.sql), satır 72.
- [Olay dönüşümü](../apps/web/src/lib/billing/revenuecat.ts), satır 93–98.

RevenueCat'in güncel resmi belgesi, planlanan pause olayında erişimin kesilmemesini ve billing issue olayının tek başına expiry anlamına gelmediğini açıklar. Transfer, extension ve refund reversal olayları da tanımlıdır. [Resmi olay sözleşmesi](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields).

Geçen ödeme kontrolleri: ilk satın alma ve 125 özet hakkı; tekrar olayın idempotency'si; aynı transaction zincirindeki eski olayın reddi; normal iptalde dönem sonuna kadar erişim; expiry sonrası read-only; organizasyon alanına native ödeme reddi. İlk iki olay sırası kontrolü tek test senaryosunda birlikte çalışır.

## Canlı web kontrolü

24 Eylül sabahı kimliksiz ve veri değiştirmeyen HTTP kontrolleri: **12 PASS, 2 FAIL** (13 HTTP isteği ve ayrıca fiyat içeriği kontrolü).

- Public ana sayfa, privacy, terms, account-deletion ve login: 200.
- Session, müşteriler, ziyaretler, görevler, billing, invitations ve PDF export: oturumsuz 401.
- **P1:** `POST https://app.kartvizyon.app/api/internal/webhooks/revenuecat` → **404**. Yeni ödeme endpoint'inin canlı adreste erişilebilirliği başarısız. Kaynakta bulunması deploy edildiğini kanıtlamaz.
- **P1:** Public bireysel kart hâlâ **349 TL/ay, yıllık 3490 TL, 120 AI dakika/60 OCR** gösteriyor. Yeni karar 449 TL/ay, 240 dakika, 125 OCR/125 özet ve yalnız aylık ürün. Sayfadaki 449 sayısı kurumsal karta ait; basit “449 içeriyor” testi yanıltıcı olur.

Kanıt: `artifacts/prebuild-2026-09-23/http-smoke-results.json`. Bu ölçüm canlı sürüme aittir; yerel yeni kodun görsel/tarayıcı E2E sonucu değildir.

## Diğer kod inceleme bulguları ve kapsam boşlukları

- **P2 — Satın alma sonrası ağ hatası:** `premium_screen.dart` içindeki buy/restore yalnız `StoreBillingException` yakalıyor. `refreshServerStatus` HTTP hatasında `MobileApiException` atabiliyor. Ödeme başarılıyken sunucu sorgusu bozulursa anlaşılır bekleme/yeniden eşitleme mesajı yerine yakalanmamış async hata riski var. Kod inceleme bulgusu; gerçek SDK satın almasıyla tekrar üretilmedi.
- **P2 — Olay kapsamı:** `TRANSFER`, `SUBSCRIPTION_EXTENDED`, `REFUND_REVERSED` varsayılan ignored yoluna gidiyor. Transfer politikası ve entitlement uzlaştırması olmadan store lifecycle tam kabul edilemez.
- **P2 — Kimlik fallback'i:** `app_user_id` UUID zorunlu; RevenueCat anonim ID gönderirken geçerli UUID alias bulunsa dahi şema önce reddediyor. Normal uygulama Supabase UUID kullanıyor; anonim/alias ve hesap değişimi ayrıca test edilmeli.
- **P2 — Secret denetimi:** `verify-no-secrets.mjs` listesinde iki `REVENUECAT_WEBHOOK_*` sırrı yok. Bu bir sızıntı kanıtı değil, tarama kapsamı eksikliğidir. Yeni build üretilmediği için eski `.next` çıktısı güncel kod adına onaylanmadı.
- **P2 — Güncelliğini yitiren belgeler:** README/CLAUDE ödeme kapalı diyor; PRE_RELEASE_TESTS 21 migration, 263 test ve eski ücretsiz katman örneği içeriyor; MOBILE_WEB_PARITY ödemeyi yalnız webde gösteriyor; ROADMAP Ağustos production durumunu anlatıyor. `0027` yorumunda referans verilen ADR-0009 dosyası yok. Yeni model için tek güncel release kaydı gerekli.
- **Cihaz sınırı:** Geçmiş bildirim çalışmasında local delivery var, webde oluşturulan yeni kaydın hiç açılmamış uygulamaya ulaşması için remote push eksik. Fiziksel iOS/Android reboot, terminated tap, arka plan konum, pil ve izin turu bu oturumda çalıştırılmadı.
- **Hata geçmişi:** CLOSED_TEST_ISSUES dosyasında eski 504/login düzeltmeleri, görev offline sınırı ve nedeni kesinleşmemiş iOS watchdog kaydı var. Bunlar güncel Sentry sorgusu değildir; yeni mağaza sürümünde kapandıkları varsayılmadı.

## Bu incelemede yapılan değişiklikler

- Test öncesi uzman promptu ve bu rapor yazıldı.
- RevenueCat HTTP handler'ına 11 davranış testi eklendi: yapılandırma, auth, eski imza, gövde tahrifi, bozuk JSON/şema, TEST, eksik işlem kimliği, eşlenmeyen ürün, RPC'ye güvenilir veri aktarımı ve duplicate yanıtı.
- Field Mode testlerinin gerçek saate bağımlılığı düzeltildi. Servise varsayılanı yine `DateTime.now` olan saat bağımlılığı eklendi; testler sabit gündüz saati kullanıyor. Ayrıca tam 21.00'de başlamama regresyon testi eklendi. Ürünün gece kapanış kuralı korundu.
- İzole ödeme davranışı ve canlı HTTP/fiyat denetimleri tekrar çalıştırılabilir script/JSON olarak kaydedildi.
- Ödeme politikası, production verisi veya eski migration'lar değiştirilmedi. Ödeme hataları bu incelemenin açık bulgularıdır.

## Otomatik test sonuçları

| Kontrol                             | Sonuç                                                         |
| ----------------------------------- | ------------------------------------------------------------- |
| Format                              | PASS — son tam format kontrolü de geçti                       |
| Migration doğrulama                 | PASS — 34 up/down çifti                                       |
| Lint / TypeScript                   | PASS — ilk tam kontrol ve değişiklik sonrası web kontrolleri  |
| Web son tam tur                     | 111/111 PASS (11 yeni webhook testi dahil)                    |
| Yeni webhook HTTP testleri          | 11/11 PASS                                                    |
| Contracts                           | 37/37 PASS                                                    |
| Database                            | 259/259 PASS; statik ve PGlite davranış testleri birlikte     |
| Document scanner                    | 3/3 PASS                                                      |
| Flutter analyze                     | PASS — son analizde sorun yok                                 |
| İlk Flutter turu                    | 112 PASS, 4 FAIL — saat bağımlılığı                           |
| Saat düzeltmesi odaklı tur          | 11/11 PASS; auth ve zaman sınırları                           |
| Son Flutter turu                    | 117/117 PASS                                                  |
| npm production bağımlılık audit     | PASS — 0 bilinen açık; tüm kaynak güvenli demek değildir      |
| Ek ödeme davranış denetimi          | 5 PASS, 5 FAIL — build engeli                                 |
| Canlı HTTP + fiyat                  | 12 PASS, 2 FAIL — yayın farkı                                 |
| Yeni build / binary secret taraması | ÇALIŞTIRILMADI — build talebi yok; eski çıktı kanıt sayılmadı |

Loglar: `artifacts/prebuild-2026-09-23/`. `.log` dosyaları mevcut gitignore nedeniyle takip edilmez; yerelde korunur. Denetim `.mjs` ve `.json` dosyaları yeniden üretim kanıtını taşır.

## Build öncesi kapanış koşulları

1. Yukarıdaki beş ödeme davranışı kontrolü gerçek sözleşme beklentileriyle yeşile dönmeli; transfer/sandbox/grace kararları uygulanmalı.
2. Satın alma sonrası ağ hatası, restore, pending, kullanıcı değişimi ve offline/restart davranışı test edilmeli.
3. Apple/Google ürün → premium entitlement → default monthly offering → doğru public SDK key → doğrulanmış webhook zinciri güncel konsollardan teyit edilmeli.
4. Staging'de gerçek sandbox satın alma/yenileme/iptal/expiry/restore, güvenilir server hakları ve iki hesap/iki workspace senaryoları tamamlanmalı.
5. Web yayını güncel fiyat ve ödeme endpoint'iyle eşitlenmeli; production migration ledger ayrıca doğrulanmalı. Bu rapor deploy yapıldığı anlamına gelmez.
6. Sonra istenen tek release build üzerinde secret taraması ve gerçek iPhone/Android kabul turu yapılmalı. Bu kontroller için build gereklidir; build öncesinde tamamlandı denemez.
