# Apple App Store ve Google Play yayın dosyası

## Uygulama kimliği

- Ad: KartVizyon AI
- Android applicationId: `app.kartvizyon.mobile`
- iOS bundle ID: `app.kartvizyon.mobile` (Apple ID 6797552440, SKU `KARTVIZYON-IOS-001`)
- iOS cihaz ailesi: yalnız iPhone (`TARGETED_DEVICE_FAMILY = "1"`); iPad sonraki sürüme bırakıldı
- Web: `https://kartvizyon.app`
- Uygulama yönetimi: `https://app.kartvizyon.app`
- Gizlilik: `https://kartvizyon.app/privacy`
- Destek: `https://kartvizyon.app/support`
- Hesap silme: `https://kartvizyon.app/account-deletion`
- Sağlayıcı: Noesis Social - Burak OHRİLİ, Ege VD. 6360302767

## Diğer uygulamaları koruma ilkesi

- KartVizyon için yeni App ID/bundle ID kullanılır. Android upload keystore yerelde üretildi; Codemagic'e yalnız `kartvizyon_upload` referansıyla yüklenecek.
- Apple’da yalnız `app.kartvizyon.mobile` profilleri seçilir; mevcut wildcard veya başka uygulama profili kullanılmaz.
- App Store Connect API anahtarı `kartvizyon_app_store` adıyla, App Manager rolünde ve Codemagic entegrasyonunda tutulur.
- Google service account yalnız KartVizyon uygulamasının Releases iznine sahip olur; finans ve diğer uygulama izinleri verilmez.
- Android keystore referansı yalnız `kartvizyon_upload` olur. Keystore’un şifreli offline yedeği ayrıca saklanır; Codemagic’den geri indirilemeyeceği unutulmaz.
- Upload sertifikası SHA-256 parmak izi: `DF:C8:E6:A5:F1:44:5C:E2:0C:0D:77:C6:74:FE:4A:2B:B4:91:2A:76:C2:DB:E9:DE:51:91:ED:65:36:A2:63:11`. Bu kayıt diğer dört uygulamanın anahtarlarıyla karışmayı önleyen yayın kontrolüdür.

## İzin gerekçeleri

| İzin                | Kullanım                                             | Alternatif                     |
| ------------------- | ---------------------------------------------------- | ------------------------------ |
| Kamera              | Kullanıcının seçtiği kartvizit/belgeyi yakalama      | Galeri veya manuel kişi girişi |
| Fotoğraf            | Seçili kartvizit/belge yükleme                       | Kamera veya manuel giriş       |
| Mikrofon            | Ziyaret sonrası kullanıcının başlattığı debrief      | Metin notu                     |
| Konum (kullanırken) | Kullanıcının istediği anda yakındaki müşteri/ziyaret | Arama ve manuel adres          |

Arka plan konumu, rehber, SMS, reklam kimliği ve izleme izni kullanılmaz. İzinler onboarding’de topluca değil, özellik ilk kez kullanıldığında istenir.

## İnceleme hesabı

Production backend’de `reviewer@kartvizyon.app` kullanıcısı otomatik onaylı olarak oluşturuldu. Hesabın `KartVizyon İnceleme Alanı` kişisel çalışma alanında iki müşteri, iki ziyaret, görevler, fırsat, ürün, müşteri hafıza kartı, form ve bildirim bulunur. MFA kapalıdır. Parola yalnız App Store Connect/Play Console reviewer alanında ve işletme sahibinin parola kasasında tutulur; repoya yazılmaz.

App Review / Play notes metni:

> KartVizyon, saha satış görüşmelerini kullanıcı onaylı müşteri hafızasına dönüştürür. İnceleme hesabı e-posta veya MFA doğrulaması istemez. “Ziyaretler → Demo ziyaret → Debrief” yolunda örnek AI taslağı görülebilir; “Daha Fazla → KVKK ve veri hakları” altında veri dışa aktarma ve hesap silme başlatılabilir. Kamera, mikrofon ve konum reddedilirse manuel alternatifler kullanılabilir. Uygulama arka planda konum izlemez.

Kimlik bilgileri App Store Connect ve Play Console’un reviewer alanına girilir; public dokümana veya repoya yazılmaz.

## Mağaza uyumluluk kapısı

- [x] Uygulama içinden hesap silme talebi başlatma ekranı
- [x] Public gizlilik, destek ve hesap silme URL’leri
- [x] İzin açıklamaları ve manuel alternatif tasarımı
- [x] İnsan onaylı AI açıklaması
- [x] Production bundle/application ID ayrıştırması
- [x] Debug signing ile release üretimini engelleme
- [x] Reviewer hesabı, production Supabase oturumu ve demo verisi
- [x] 1024×1024 opak mağaza ikon kaynağı
- [x] Sentry web/mobil SDK kodu ve kişisel veri maskeleme varsayılanları
- [x] Launcher icon set üretimi (22 iOS AppIcon, 5 Android mipmap)
- [x] Play feature graphic ve telefon/tablet ekran görüntüleri (mağaza girişi "Canlı")
- [x] Google Play Data safety formu (9 politika beyanı tamamlandı)
- [x] iOS gerçek cihaz testi (TestFlight build 11–12 kuruldu ve çalıştırıldı)
- [x] Bireysel abonelik fiyat kararı (ADR-0005) ve kota uygulaması
- [ ] Production hesap silme worker akışının uçtan uca doğrulanması
- [ ] App Store Connect App Privacy formunun konsolda gönderilmesi
- [ ] iPhone 6.5" ekran görüntüleri (iPad artık gerekmiyor; cihaz ailesi yalnız iPhone)
- [ ] Play içerik derecelendirme anketi
- [ ] Play üretim erişimi: 12 test kullanıcısı × 14 gün kapalı test
- [ ] Android düşük/orta segment regresyon testi
- [ ] Mağaza içi satın alma (ADR-0004 Faz C) — bu sürümde kapsam dışı

Apple hesap oluşturan uygulamalarda uygulama içinden hesap silme başlatmayı ve etkin demo hesabı ister. Google Play ilk AAB yüklemesinin manuel yapılmasını gerektirir; sonraki sürümler Codemagic servis hesabıyla internal track’e gönderilebilir.

Resmi kontrol kaynakları: [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [Apple hesap silme](https://developer.apple.com/support/offering-account-deletion-in-your-app/), [Google Play hesap silme](https://support.google.com/googleplay/android-developer/answer/13327111), [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), [Codemagic iOS signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/) ve [Codemagic Android signing](https://docs.codemagic.io/yaml-code-signing/signing-android/).

## App Privacy / Data safety çalışma matrisi

| Veri                            | Amaç                                  |                            Kimliğe bağlı | Paylaşım/izleme                      | Silme                                                    |
| ------------------------------- | ------------------------------------- | ---------------------------------------: | ------------------------------------ | -------------------------------------------------------- |
| E-posta, ad, kullanıcı kimliği  | Hesap ve kimlik doğrulama             |                                     Evet | Reklam/izleme yok                    | Hesapla silinir                                          |
| Müşteri/kişi ve satış kayıtları | Uygulama işlevi                       |                    Çalışma alanına bağlı | Kurum üyeleri dışında paylaşılmaz    | Kişisel alanda silinir; kurumsal yasal kayıt anonimleşir |
| Ses, transkript, not            | Kullanıcının başlattığı debrief ve AI |                                     Evet | OpenAI işlem sağlayıcısı; reklam yok | Retention veya hesap silme ile silinir                   |
| Fotoğraf/kartvizit/belge        | OCR, müşteri kaydı, belge işlevi      |                                     Evet | İşlem sağlayıcıları; reklam yok      | Hesap/retention politikasına göre silinir                |
| Kullanırken konum               | Yakındaki müşteri ve açık check-in    |                                     Evet | Satış/izleme yok                     | İlgili kayıtla silinir                                   |
| Hata ve performans telemetrisi  | Güvenlik ve kararlılık                | PII kapalı, teknik kullanıcı ID olabilir | Sentry; reklam/izleme yok            | Sentry retention politikasına göre                       |

Mağaza beyanı SDK envanteriyle birebir aynı tutulur: Supabase Auth/Database, OpenAI sunucu tarafı, Sentry, `image_picker`, `record`, `geolocator`, `connectivity_plus`, secure storage ve Drift. Uygulama reklam kimliği, ATT, arka plan konumu, rehber veya SMS istemez.

## Codemagic kurulum sırası (tamamlandı)

Aşağıdaki adımlar 10 Ağustos 2026 tarihinde uygulanmış ve her iki workflow da
başarıyla çalışmıştır. Güncel ve düzeltilmiş sıra için
`docs/EXTERNAL_SETUP_RUNBOOK.md` §3 esas alınır.

1. GitHub reposunu Codemagic’e ekle.
2. `mobile_runtime` grubuna `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SENTRY_DSN` secret değerlerini gir.
3. `apps/mobile/android/kartvizyon-upload.jks` dosyasını yükle, referansı `kartvizyon_upload` yap ve `key.properties` ile birlikte şifreli ayrı yedekle. Bu iki dosyayı repoya ekleme.
4. Apple’da yeni `app.kartvizyon.mobile` App ID ve App Store kaydı oluştur.
5. App Store Connect’te özel Codemagic API key üret; entegrasyon adı `kartvizyon_app_store`.
6. Codemagic’de yalnız bu bundle ID için Apple Distribution sertifikası/provisioning profile üret.
7. Önce publish kapalı signed AAB/IPA build’leri çalıştır; cihazlarda doğrula.
8. iOS workflow input `submitToTestFlight=true` ile TestFlight’a yükle.
9. İlk AAB’yi Play Console’a manuel internal release olarak yükle. Sonrasında service account otomasyonu eklenir.

Ödeme mimarisi kesinleşmeden bireysel paket satın alma CTA’sı ve mağaza abonelik ürünleri yayına alınmaz.
