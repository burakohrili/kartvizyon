# App Store Connect gönderim çalışma listesi

Bu belge konsola girilecek her alanı kopyala-yapıştır sırasıyla toplar.
Uygulama kaydı zaten mevcuttur: **Apple ID 6797552440**, SKU `KARTVIZYON-IOS-001`,
bundle `app.kartvizyon.mobile`. TestFlight'ta build 5, 7, 9, 11 ve 12 yüklüdür.

Metinlerin kaynağı `docs/STORE_LISTING_TR.md`, gizlilik matrisi
`docs/STORE_RELEASE.md`, fiyat kararı `docs/product/decisions/0005-pricing.md`.

> Cihaz ailesi `TARGETED_DEVICE_FAMILY = "1"` (yalnız iPhone) yapıldığı için
> **iPad ekran görüntüsü istenmez.**

---

## 1. App Information

| Alan                | Değer                                        |
| ------------------- | -------------------------------------------- |
| Name                | `KartVizyon AI`                              |
| Subtitle (30 krktr) | `Saha satış hafızası`                        |
| Primary Category    | Business                                     |
| Secondary Category  | Productivity                                 |
| Primary Language    | Turkish                                      |
| Content Rights      | "Bu uygulama üçüncü taraf içeriği içermiyor" |
| License Agreement   | Apple Standard License Agreement             |

**Age Rating anketi** — tüm içerik sorularına `None` / `Yok`; sınırsız web
erişimi **yok**; kullanıcı üretimi içerik **yok** (veriler yalnız kullanıcının
kendi çalışma alanında görünür, herkese açık paylaşım yoktur); kumar, şiddet,
yetişkin içerik **yok**. Beklenen sonuç: **4+**.

---

## 2. Pricing and Availability

- Price: **Free** — bu sürümde hiçbir kanalda ücretli satış yoktur
- Availability: tüm ülkeler/bölgeler
- Tax Category: **Software / SaaS** (uygulama içi satın alma yoktur)

---

## 3. App Privacy

Privacy Policy URL: `https://kartvizyon.app/privacy`

`docs/STORE_RELEASE.md` matrisine göre doldurulur. Özet:

| Veri türü                       | Toplanır | Amaç                                 | Kimliğe bağlı | İzleme |
| ------------------------------- | -------- | ------------------------------------ | ------------- | ------ |
| E-posta, ad, kullanıcı kimliği  | Evet     | Uygulama işlevi, kimlik doğrulama    | Evet          | Hayır  |
| Müşteri/kişi ve satış kayıtları | Evet     | Uygulama işlevi                      | Evet          | Hayır  |
| Ses, transkript, not            | Evet     | Uygulama işlevi (kullanıcı başlatır) | Evet          | Hayır  |
| Fotoğraf (kartvizit/belge)      | Evet     | Uygulama işlevi                      | Evet          | Hayır  |
| Kullanırken konum               | Evet     | Uygulama işlevi                      | Evet          | Hayır  |
| Hata/performans telemetrisi     | Evet     | Analitik ve uygulama işlevi          | Hayır         | Hayır  |

**"Used to Track You" hiçbir kalemde işaretlenmez.** Reklam kimliği, ATT,
arka plan konumu, rehber ve SMS kullanılmaz.

SDK envanteri beyanla birebir aynıdır: Supabase Auth/Database, OpenAI (sunucu
tarafı), Sentry, `image_picker`, `record`, `geolocator`, `connectivity_plus`,
secure storage, Drift.

---

## 4. Sürüm 1.0 — App Store sekmesi

**Promotional Text (170)**

```
Her müşteri görüşmesine bağlamıyla hazırlanın. Ziyaret notlarını, sesli debrief taslaklarını ve açık takipleri insan onaylı bir saha hafızasında birleştirin.
```

**Description**

```
KartVizyon AI, saha satış ekiplerinin müşteri bağlamını kaybetmeden çalışmasına yardımcı olur.

Ziyaretten önce son görüşmeleri, açık sözleri ve kritik notları tek brifingde görün. Ziyaret sonrasında sesli veya yazılı debrief oluşturun; yapay zekânın hazırladığı özet ve takip taslağını kontrol edip onaylayın. Onaylanmayan AI çıktısı kurumsal hafızaya eklenmez.

Öne çıkanlar:

- Müşteri ve kişi hafızası
- Ziyaret planlama ve saha debrief akışı
- İnsan onaylı AI özetleri ve takip önerileri
- Görev, fırsat, ürün ve sipariş taslağı görünümü
- Kartvizit OCR ve belge karantinası
- Çevrimdışı taslak ve güvenli senkronizasyon
- Rol ve çalışma alanı bazlı kurumsal erişim
- KVKK rıza, veri dışa aktarma ve hesap silme merkezi

KartVizyon sürekli konum takibi yapmaz. Kamera, mikrofon ve konum yalnız ilgili özelliği siz başlattığınızda istenir; reddedildiğinde manuel alternatifler kullanılabilir.

Bireysel saha profesyonelleri ve kurumsal satış ekipleri için tasarlanmıştır.
```

**Keywords (100)**

```
saha satış,müşteri,ziyaret,CRM,takip,görev,not,brifing,offline,AI
```

**Support URL** → `https://kartvizyon.app/support`
**Marketing URL** → `https://kartvizyon.app`
**Copyright** → `2026 Noesis Social - Burak OHRİLİ`

**Version release** → `Manually release this version` (ilk sürümde kontrollü çıkış)

**Build** → TestFlight'taki **build 12** sürüme eklenir (commit `bf20b2a`).

---

## 5. Ekran görüntüleri

- Gerekli tek boyut: **iPhone 6.5"** — 1284 × 2778 veya 1242 × 2688 piksel
- En az 3, en fazla 10 adet. İlk 3 tanesi yükleme sayfasında görünür.
- Önerilen sıra: Bugün özeti → Müşteriler → Ziyaret debrief / AI incelemesi →
  Görevler → KVKK merkezi
- Durum çubuğunda gerçek saat/pil görünmesi sorun değildir; **sahte veri kullanılmaz**,
  reviewer demo çalışma alanı içeriği kullanılır.

---

## 6. App Review Information

| Alan               | Değer                                   |
| ------------------ | --------------------------------------- |
| Sign-in required   | ✅ işaretli                             |
| User name          | `reviewer@kartvizyon.app`               |
| Password           | **parola kasasından** — repoya yazılmaz |
| Contact First Name | Burak                                   |
| Contact Last Name  | OHRİLİ                                  |
| Phone              | **kullanıcıdan alınacak**               |
| Email              | `kartvizyonapp@gmail.com`               |

**Notes**

```
KartVizyon, saha satış görüşmelerini kullanıcı onaylı müşteri hafızasına dönüştürür. İnceleme hesabı e-posta doğrulaması veya MFA istemez.

1. reviewer@kartvizyon.app ile giriş yapın.
2. Bugün ekranında canlı demo çalışma alanını ve onay bekleyen ziyareti görün.
3. Müşteriler → Atlas Medikal ile hafıza ve kişi verisini inceleyin.
4. Ziyaretler bölümünde demo debrief akışını açın; AI taslağı "incelemede" durumundadır ve onaylanmadan kurumsal kayda geçmez.
5. Daha Fazla → KVKK ve veri hakları altında veri dışa aktarma ve hesap silme talebi başlatılabilir.

Kamera, mikrofon veya konum izni reddedilebilir; uygulama manuel yollarla çalışmaya devam eder. Arka plan konumu yalnız kullanıcının başlattığı saha modu süresince ve görünür göstergeyle (Android kalıcı bildirim, iOS mavi konum çubuğu) alınır; uygulama kapalıyken konum izlenmez. Bu sürümde uygulama tamamen ücretsizdir: hiçbir platformda ücretli abonelik, uygulama içi satın alma veya ödeme akışı bulunmaz ve tüm hesaplar ücretsiz kullanır. Backend inceleme boyunca açık tutulacaktır.
```

---

## 7. Gönderim öncesi son kontrol

- [ ] App Information: kategori, subtitle, content rights, age rating tamam
- [ ] App Privacy anketi gönderildi ve privacy policy URL girildi
- [ ] Pricing: Free + tax category seçildi
- [ ] Sürüm sayfası: açıklama, keywords, URL'ler, copyright dolu
- [ ] 3+ iPhone 6.5" ekran görüntüsü yüklendi
- [ ] Build 12 sürüme eklendi
- [ ] App Review sign-in bilgileri ve notlar girildi
- [ ] `Add for Review` → gönderildi

## 8. İzin beyanı — App Review 5.1.1

Beyan edilen her izin kodda fiilen kullanılmalıdır; kullanılmayan izin
"gereksiz veri toplama" sayılır ve reddedilir. `apps/mobile/test/store_compliance_test.dart`
bunu her build'de doğrular.

| Anahtar                               | Kullanım                               | Alternatif (reddedilirse)     |
| ------------------------------------- | -------------------------------------- | ----------------------------- |
| `NSCameraUsageDescription`            | Kartvizit fotoğrafı çekme              | Galeriden seçme, manuel giriş |
| `NSPhotoLibraryUsageDescription`      | Galeriden kartvizit seçme              | Kamera, manuel giriş          |
| `NSMicrophoneUsageDescription`        | Kullanıcının başlattığı sesli debrief  | Metin notu                    |
| `NSLocationWhenInUseUsageDescription` | Yakındaki müşteri önerisi ve saha modu | Müşteri arama, manuel adres   |
| `UIBackgroundModes: location`         | Saha modu açıkken arka planda konum    | Saha modunu hiç açmamak       |

**Saha modu `Always` yetkisi istemez.** Arka planda konum alınır ama oturum
kullanıcı tarafından başlatılır, mavi konum göstergesi açık kalır
(`showBackgroundLocationIndicator: true`) ve oturum kendiliğinden kapanır.
Reviewer bunu Bugün ekranındaki "Saha modunu başlat" düğmesiyle görebilir;
"Saha modunu bitir" ile durdurulur. Ayrıntı: ADR-0006.

**`NSLocationAlwaysAndWhenInUseUsageDescription` vardır ama _Always_ yetkisi
istenmez.** Anahtar 18 Ağustos 2026'da "geolocator'ı Always istemeye iter"
gerekçesiyle kaldırılmıştı; gerekçe yanlıştı ve 19 Ağustos'ta geri kondu.
`geolocator_apple` önce `NSLocationWhenInUseUsageDescription`'a bakıp
`requestWhenInUseAuthorization` çağırıyor, Always dalına yalnız o anahtar
yokken giriyor — yani bizde ölü kod. Anahtarsız her teslimat `ITMS-90683`
uyarısı üretiyordu.

> Reviewer'a söylenecek: uygulama yalnız "Uygulamayı kullanırken" yetkisi
> ister. Açıklama metni de bunu yazar; anahtar Apple'ın statik denetimi bağlı
> SDK'ların referansları yüzünden zorunlu tuttuğu için bulunur.
> Ayrıntı: ADR-0006.

Reviewer izinleri reddederek test edebilir; uygulama her üç yolda da manuel
alternatifle çalışmaya devam eder.

## 9. Ödeme ifadeleri hakkında uyarı

Reviewer notunda ve açıklamada **"abonelik web üzerinden yönetilir"** benzeri bir
ifade kullanılmaz. İki sebep:

1. **Doğru değil.** Bu sürümde web'de de checkout yok; iyzico bağlanmadı, hiçbir
   kanalda ücretli abonelik satılmıyor. Tüm hesaplar deneme veya ücretsiz katmanda.
2. **Reddedilme riski.** ADR-0004'ün açıkça belirttiği gibi Apple, dışarıda satın
   alınmış aboneliğe giriş yapılan uygulamaları App Review Guidelines **3.1.1**
   kapsamında düzenli olarak reddediyor. Reviewer'a "abonelik web'de satılıyor"
   demek, bu maddeyi kendi elimizle davet etmek olur.

Doğru ifade: **bu sürümde hiçbir platformda ücretli satış yoktur.** Ödeme akışı
(ADR-0005 fiyatları, iyzico checkout ve mobil IAP) devreye girdiğinde bu metinler
ADR-0004'teki kanal ayrımına göre yeniden yazılır.

## 10. Bu sürümde bilinçli olarak yapılmayanlar

- Uygulama içi satın alma ve abonelik ürünü (ADR-0004 Faz C; AAB/IPA'ya önce
  ödeme kütüphanesi eklenmeli)
- iPad desteği (`TARGETED_DEVICE_FAMILY = "1"`)
- Arka plan konumu — ürün ilkesi gereği hiç istenmez
- Apple Silicon Mac ve Vision Pro dağıtımı
