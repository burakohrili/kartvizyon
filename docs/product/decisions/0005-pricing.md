# ADR-0005 — Fiyat noktaları, ücretsiz katman ve AI maliyet modeli

- Durum: kabul edildi
- Tarih: 17 Ağustos 2026
- Kapattığı karar: ADR-0004 "Bekleyen kararlar" bölümü (fiyat noktaları belirsizdi)
- Bağlam: ADR-0003 (tahsilat sağlayıcısı iyzico), ADR-0004 (iki kanal, tek entitlement)

## Bağlam

ADR-0004 satış kanallarını ve entitlement mimarisini belirledi ama fiyatları açıkta
bıraktı. Fiyat kesinleşmeden ne plan tohumları yazılabiliyor, ne iyzico ürün tanımı
yapılabiliyor, ne de pazarlama sitesinde rakam yayımlanabiliyordu.

Kod tarafında ticari şema hazır (`subscription_plans`, `workspace_subscriptions`,
`usage_records`) ama **hiçbir limit uygulanmıyordu**; `starter` 990 ₺ / `growth` 2490 ₺
tohumları da sabit fiyatlıydı ve koltuk başına modele uymuyordu.

## AI maliyet modeli

Resmî OpenAI fiyatları (developers.openai.com/api/docs/pricing, 17 Ağustos 2026):

| Model                  | Girdi / 1M tokens | Çıktı / 1M tokens |
| ---------------------- | ----------------: | ----------------: |
| gpt-5.6-sol            |             $5.00 |            $30.00 |
| gpt-5.6-terra          |             $2.00 |            $12.00 |
| gpt-5.6-luna           |             $0.20 |             $1.20 |
| gpt-4o-transcribe      |   $0.006 / dakika |                   |
| gpt-4o-mini-transcribe |   $0.003 / dakika |                   |

### Model kararı

| İş                  | Önce                | Sonra           | Gerekçe                                                               |
| ------------------- | ------------------- | --------------- | --------------------------------------------------------------------- |
| Ziyaret özeti       | `gpt-5.6-sol`       | `gpt-5.6-terra` | Zod ile doğrulanan yapılandırılmış çıktı; Sol'un %40 maliyeti yeterli |
| Kartvizit OCR       | `gpt-5.6-sol`       | `gpt-5.6-luna`  | Dar alan çıkarma, şema doğrulaması hatayı zaten yakalar; ~25× ucuz    |
| Ses transkripsiyonu | `gpt-4o-transcribe` | değişmedi       | Türkçe doğruluğu ürünün çekirdeği; dakikada $0.003 için risk alınmaz  |

Üç değer de `OPENAI_SUMMARY_MODEL`, `OPENAI_OCR_MODEL`, `OPENAI_TRANSCRIPTION_MODEL`
ortam değişkenleriyle override edilebilir.

### Kullanıcı başı aylık maliyet

Varsayım: 40 ziyaret, 24 sesli debrief (ort. 3 dk), 20 kartvizit taraması.

| Kalem                    | Önce ($) | Sonra ($) |
| ------------------------ | -------: | --------: |
| Transkripsiyon (72 dk)   |     0.43 |      0.43 |
| Özet (40 adet)           |     0.68 |      0.27 |
| OCR (20 adet)            |     0.23 |      0.01 |
| **Toplam**               | **1.34** |  **0.71** |
| **TL** (1 USD = 47,90 ₺) | **64 ₺** |  **34 ₺** |

Ağır kullanıcı (100 ziyaret, 80 debrief × 5 dk): ≈ $2.60 ≈ **125 ₺/ay**.

### Sabit altyapı

Vercel Pro $20 · Supabase Pro $25 (production için zorunlu; Free planda proje duraklıyor
ve otomatik yedek yok) · Cloud Run ClamAV $5–15 · Resend $0–20 · Sentry $0–26
→ **aylık $50–106 ≈ 2.400–5.100 ₺**.

**Bütçe kapısı:** OpenAI hesabında aylık **$50 hard limit**, $30'da e-posta uyarısı.
Bu limit, karar sonrası maliyetle yaklaşık 70 aktif kullanıcıyı karşılar ve kaçak
tüketimde faturayı sınırlar.

## Piyasa referansı

- Yerli giriş seviyesi: BasitCRM 6.900 ₺/yıl / 3 kullanıcı ≈ **192 ₺/kullanıcı/ay**
- Bölgesel SaaS: **$29/kullanıcı/ay ≈ 1.390 ₺**
- Yabancı CRM: **$12–50/kullanıcı/ay ≈ 575–2.400 ₺**
- Kurumsal CRM: **$65+/kullanıcı/ay ≈ 3.100 ₺**

KartVizyon genel bir CRM değil; dar kapsamlı saha hafızası + AI. Yerli giriş
seviyesinin üstünde, yabancı CRM'in belirgin altında konumlanır.

## Karar

### Planlar (KDV hariç, ₺)

| Plan         |        Aylık | Yıllık (2 ay bedava) | Min koltuk | Müşteri  | AI dk/ay (koltuk başı) | OCR/ay (koltuk başı) |
| ------------ | -----------: | -------------------: | ---------: | -------- | ---------------------: | -------------------: |
| **Ücretsiz** |            0 |                    – |          1 | 5        |                     10 |                    5 |
| **Bireysel** |          349 |                3.490 |          1 | sınırsız |                    120 |                   60 |
| **Ekip**     | 279 / koltuk |       2.790 / koltuk |          3 | sınırsız |                    150 |                   80 |
| **Kurumsal** | 449 / koltuk |               teklif |         10 | sınırsız |                    250 |             sınırsız |

- Ekip ve Kurumsal planda AI kotası **koltuk sayısıyla çarpılır ve havuzlanır**; bir
  kullanıcı az, diğeri çok kullanabilir.
- **Deneme:** yeni kişisel çalışma alanı 14 gün `trialing` (tam erişim), sonra `free`.
- Limit aşımı **yalnız yeni kayıt oluşturmayı** engeller. Mevcut veri okunabilir kalır
  ve hiçbir koşulda silinmez.

### Brüt marj

Bireysel 349 ₺ · AI maliyeti 34 ₺ (ağır kullanıcı 125 ₺) → **%64–90 marj**.
Sabit altyapı 2.400–5.100 ₺/ay olduğundan **başabaş ≈ 15–20 ödeyen kullanıcı**.

### Ek AI paketleri (top-up)

Aylık kota bitince kullanıcı çalışmaya devam edebilsin diye tek seferlik paketler.
Süresizdir; aylık kota tükendikten sonra tüketilir.

| Paket   | İçerik                 | Fiyat | Maliyet | Marj |
| ------- | ---------------------- | ----: | ------: | ---: |
| AI 100  | +100 dakika, +50 OCR   | 149 ₺ |   ~30 ₺ |  %80 |
| AI 300  | +300 dakika, +150 OCR  | 349 ₺ |   ~88 ₺ |  %75 |
| AI 1000 | +1000 dakika, +500 OCR | 899 ₺ |  ~292 ₺ |  %68 |

### Mağaza içi satın alma (IAP) fiyatı

Apple/Google Small Business komisyonu %15 olduğundan, aynı net geliri korumak için
mobil bireysel abonelik **449 ₺/ay** (web 349 ₺). ADR-0004 zaten "aynı ürünün iki
farklı fiyat noktası olabilir" demektedir. Kurumsal planlar mobilde **hiç gösterilmez**.

## Sonuçlar

- `0021_entitlements` migration'ı bu tabloları tohumlar; eski `starter`/`growth`
  planları `active = false` yapılır (mevcut FK referansları korunur).
- Pazarlama sitesindeki fiyat bölümü rakamları gösterir; **checkout ADR-0003 gereği
  yalnız `app.kartvizyon.app` üzerinde ve iyzico bağlanana kadar kapalıdır.**
- Fiyatlar yılda bir veya USD/TRY kurunda %25'i aşan hareket olduğunda gözden geçirilir;
  değişiklik bu ADR'ye ek olarak işlenir.
- Mobil uygulamada fiyat, satın alma butonu veya `kartvizyon.app` fiyat sayfasına
  tıklanabilir bağlantı **bulunmaz** (ADR-0004 değişmez kuralı); regresyon testiyle sabitlenir.

## Kaynaklar

- OpenAI API fiyat sayfası (17 Ağustos 2026)
- USD/TRY = 47,90 (17 Ağustos 2026)
- Türkiye CRM pazarı fiyat karşılaştırmaları (BasitCRM, Rapitek, yabancı CRM listeleri)
