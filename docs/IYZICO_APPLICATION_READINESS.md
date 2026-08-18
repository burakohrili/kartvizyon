# iyzico başvuru hazırlık denetimi

Son denetim: 18 Ağustos 2026

Bu belge iyzico hesabı açmaz, başvuru göndermez ve ödeme entegrasyonunu etkinleştirmez.
Amaç, `kartvizyon.app` sitesini iyzico'nun yayımladığı üye işyeri başvuru koşullarına
karşı doğrulamak ve başvuru öncesi eksikleri görünür tutmaktır.

Resmî kaynaklar:

- https://www.iyzico.com/isim-icin/hesap-olustur
- https://www.iyzico.com/isim-icin/sanal-pos
- https://docs.iyzico.com/urunler/abonelik

## Site kontrol listesi

| Koşul                                                         | Durum                            | Kanıt / eksik                                                                         |
| ------------------------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------- |
| Site, hizmet ve ürün bilgileriyle kullanıma hazır             | Hazır                            | Ana sayfa, sekiz özellik, üç plan ve SSS                                              |
| HTTPS / SSL                                                   | Hazır                            | `https://kartvizyon.app`; Vercel sertifika yönetimi                                   |
| Gizlilik politikası                                           | Hazır                            | `/privacy`                                                                            |
| Hakkımızda                                                    | Hazır                            | `/about`                                                                              |
| Mesafeli satış sözleşmesi                                     | **Hazır**                        | `/distance-sales` — plan, dönem, bedel tablosu ve deneme koşulu eklendi (ADR-0005)    |
| Hizmet teslim, iptal ve iade koşulları                        | **Hazır**                        | `/delivery-refund` + `docs/BILLING_INVOICE_PROCESS.md`                                |
| Ürün/hizmet fiyatları                                         | **Hazır**                        | ADR-0005; `apps/web/src/lib/pricing.ts` tek kaynak, sitede ve sözleşmede yayımlanıyor |
| Ödeme öncesi plan, dönem, toplam bedel ve yenileme açıklaması | **Bileşen hazır**                | `apps/web/src/app/pre-purchase-disclosure.tsx`; checkout'a bağlanmayı bekliyor        |
| Fatura ve iade süreci                                         | **Hazır**                        | `docs/BILLING_INVOICE_PROCESS.md`                                                     |
| Ana sayfadan doğrudan iletişim                                | Kısmen hazır                     | İşletme, VKN, adres ve e-posta yayımlanıyor; telefon eksik                            |
| KEP, telefon ve oda/meslek kuralları                          | **Eksik kullanıcı bilgisi**      | Gerçek değerler alınmadan yayımlanamaz                                                |
| iyzico ile Öde, Visa, Mastercard işaretleri                   | **Başvuru/marka paketi sonrası** | Resmî logo paketi kullanılarak checkout ve uygun site alanına eklenmeli               |
| Faaliyete özel lisans/belge                                   | Değerlendirilmeli                | SaaS faaliyeti için mali müşavir/avukat teyidi                                        |

## Kullanıcıdan zorunlu bilgiler

Bunlar uydurulamaz; başvuru öncesi işletme sahibinden alınmalıdır.

1. Başvuruda ve sitede yayımlanacak **telefon numarası**.
2. **KEP adresi**.
3. Kayıtlı olunan **meslek odası** ve ilgili davranış kurallarının çevrimiçi bağlantısı.
4. **Vergi levhası**, imza beyannamesi/sirküleri, kimlik ve işletme adına **IBAN** kanıtı.
5. e-Fatura/e-Arşiv mükellefiyet durumu ve kullanılacak entegratör.

Bu beş kalem tamamlanmadan "başvuruya tamamen hazır" sonucu verilemez.

## Fiyat ve ürün tanımı (iyzico Subscription için)

ADR-0005 rakamları. iyzico ürün/plan tanımları bunlarla birebir kurulur.

| Ürün     | Plan kodu    |          Aylık | Yıllık         | Not                   |
| -------- | ------------ | -------------: | -------------- | --------------------- |
| Bireysel | `individual` |          349 ₺ | 3.490 ₺        | 1 koltuk              |
| Ekip     | `team`       | 279 ₺ / koltuk | 2.790 ₺/koltuk | En az 3 koltuk        |
| Kurumsal | `enterprise` | 449 ₺ / koltuk | teklif         | En az 10 koltuk       |
| AI 100   | `ai_100`     |          149 ₺ | —              | Tek seferlik ek paket |
| AI 300   | `ai_300`     |          349 ₺ | —              | Tek seferlik ek paket |
| AI 1000  | `ai_1000`    |          899 ₺ | —              | Tek seferlik ek paket |

Tümü KDV hariçtir; ödeme ekranında KDV dâhil toplam gösterilir.

## Entegrasyon aşamasına bırakılanlar

Kullanıcının kararıyla checkout ve webhook bağlantısı en sona bırakılmıştır:

1. iyzico sandbox hesabı ve yukarıdaki ürün/plan tanımları
2. Koltuk seçimli checkout ekranı (`app.kartvizyon.app`) — `PrePurchaseDisclosure` bağlanır
3. `POST /api/internal/webhooks/iyzico` — imza doğrulama, idempotent işleme, audit kaydı
4. Plan yükseltme / koltuk değiştirme / iptal ekranları
5. AI ek paketi satın alma akışı (`workspace_ai_topups` yazımı yalnız sunucu tarafında)
6. Sandbox → production geçişi ve gerçek kart testi

## Hukuki uyarı

Hukuki metinler yayına ve tahsilata açılmadan önce Türkiye tüketici/e-ticaret
hukukunda uzman bir profesyonel tarafından gözden geçirilmelidir.
