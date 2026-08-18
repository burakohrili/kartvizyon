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

- Price: **Free** (abonelik bağlanana kadar; ADR-0003 gereği satın alma yalnız web'de)
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

Bireysel saha profesyonelleri ve kurumsal satış ekipleri için tasarlanmıştır. Abonelik yönetimi web üzerinden yapılır; bu sürümde uygulama içi satın alma bulunmaz.
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

Kamera, mikrofon veya konum izni reddedilebilir; uygulama manuel yollarla çalışmaya devam eder. Arka plan konumu kullanılmaz. Uygulama içi satın alma yoktur; abonelik yönetimi yalnızca web üzerinde yapılır. Backend inceleme boyunca açık tutulacaktır.
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

## 8. Bu sürümde bilinçli olarak yapılmayanlar

- Uygulama içi satın alma ve abonelik ürünü (ADR-0004 Faz C; AAB/IPA'ya önce
  ödeme kütüphanesi eklenmeli)
- iPad desteği (`TARGETED_DEVICE_FAMILY = "1"`)
- Apple Silicon Mac ve Vision Pro dağıtımı
