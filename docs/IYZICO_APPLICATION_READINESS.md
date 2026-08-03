# iyzico başvuru hazırlık denetimi

Son denetim: 3 Ağustos 2026

Bu belge iyzico hesabı açmaz, başvuru göndermez ve ödeme entegrasyonunu etkinleştirmez.
Amaç, `kartvizyon.app` sitesini iyzico'nun yayımladığı üye işyeri başvuru koşullarına
karşı doğrulamak ve başvuru öncesi eksikleri görünür tutmaktır.

Resmî kaynaklar:

- https://www.iyzico.com/isim-icin/hesap-olustur
- https://www.iyzico.com/isim-icin/sanal-pos
- https://docs.iyzico.com/urunler/abonelik

## Site kontrol listesi

| Koşul                                                         | Durum                            | Kanıt / eksik                                                                                 |
| ------------------------------------------------------------- | -------------------------------- | --------------------------------------------------------------------------------------------- |
| Site, hizmet ve ürün bilgileriyle kullanıma hazır             | Hazır                            | Ana sayfa, sekiz özellik, üç plan kapsamı ve SSS                                              |
| HTTPS / SSL                                                   | Hazır                            | `https://kartvizyon.app`; Vercel sertifika yönetimi                                           |
| Gizlilik politikası                                           | Hazır                            | `/privacy`                                                                                    |
| Hakkımızda                                                    | Hazır                            | `/about`                                                                                      |
| Mesafeli satış sözleşmesi                                     | Taslak hazır                     | `/distance-sales`; checkout fiyat/dönem bilgileri entegrasyon sırasında sözleşmeye bağlanmalı |
| Hizmet teslim, iptal ve iade koşulları                        | Taslak hazır                     | `/delivery-refund`                                                                            |
| Ana sayfadan doğrudan iletişim                                | Kısmen hazır                     | İşletme, VKN, adres ve e-posta yayımlanıyor                                                   |
| KEP, telefon ve oda/meslek kuralları                          | **Eksik kullanıcı bilgisi**      | Gerçek değerler alınmadan yayımlanamaz                                                        |
| Ürün/hizmet fiyatları                                         | **Eksik ticari karar**           | Aylık/yıllık Bireysel, Ekip ve Kurumsal fiyatları KDV durumu ile kesinleşmeli                 |
| iyzico ile Öde, Visa, Mastercard işaretleri                   | **Başvuru/marka paketi sonrası** | Resmî logo paketi kullanılarak checkout ve uygun site alanına eklenmeli                       |
| Ödeme öncesi plan, dönem, toplam bedel ve yenileme açıklaması | **Entegrasyon aşaması**          | ADR-0003 ve iyzico Subscription checkout ile uygulanacak                                      |
| Faaliyete özel lisans/belge                                   | Değerlendirilmeli                | SaaS faaliyeti için mali müşavir/avukat teyidi; gerekiyorsa başvuruda sunulmalı               |

## Kullanıcıdan zorunlu bilgiler

1. Başvuruda yayımlanacak telefon numarası.
2. KEP adresi.
3. Kayıtlı olunan meslek odası ve ilgili davranış kurallarının çevrimiçi bağlantısı.
4. Bireysel, Ekip ve Kurumsal planların aylık/yıllık KDV dâhil fiyatları veya Kurumsal
   planın açıkça “teklif usulü” kalacağı kararı.
5. Vergi levhası, imza beyannamesi/sirküleri, kimlik ve işletme adına IBAN kanıtı.

Bu bilgiler ve resmî iyzico marka paketi tamamlanmadan “başvuruya tamamen hazır” sonucu
verilemez. Hukuki metinler yayına ve tahsilata açılmadan önce Türkiye tüketici/e-ticaret
hukukunda uzman bir profesyonel tarafından gözden geçirilmelidir.
