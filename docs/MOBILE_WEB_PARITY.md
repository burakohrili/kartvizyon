# Web–mobil özellik eşlemesi

KartVizyon web ve mobil aynı çalışma alanı verisini kullanır; ekranların yerleşimi
cihazın kullanım amacına göre değişir. Mobil uygulama saha çalışanının günlük
akışına, web uygulaması ise geniş ekran ve yönetici işlemlerine öncelik verir.

## Her iki kanalda bulunan işlevler

| Alan        | Web              | Mobil                | Mobil davranışı                                         |
| ----------- | ---------------- | -------------------- | ------------------------------------------------------- |
| Günlük özet | Genel Bakış      | Bugün                | Gerçek ziyaret/görev verisi; boş hesapta sıfır gösterir |
| Müşteriler  | Müşteriler       | Müşteriler           | Firma, ilgili kişi, manuel kayıt ve kartvizit OCR       |
| Ziyaretler  | Ziyaretler       | Ziyaret              | Not, AI işleme, kullanıcı incelemesi ve onay            |
| Brifing     | Müşteri/Ziyaret  | Sıradaki ziyaret     | Hafıza kartı ve açık görevler                           |
| Görevler    | Görevler         | Görevler             | Oluşturma, tamamlama ve müşteri bağlantısı              |
| Harita      | Harita           | Saha haritası        | Açık kullanıcı işlemiyle konum; sürekli takip yok       |
| Takvim      | Takvim           | Takvim               | Ziyaret ve tarihli görev listesi                        |
| Aktivite    | Aktivite         | Aktivite             | Son onaylanan saha ziyaretleri                          |
| Raporlar    | Raporlar         | Rapor özeti          | Müşteri, onay, inceleme ve açık görev göstergeleri      |
| Bildirimler | Bildirimler      | Bildirimler          | Listeleme ve okundu işaretleme                          |
| Fırsatlar   | Fırsatlar        | Fırsatlar            | Saha için salt okunur pipeline görünümü                 |
| Ürünler     | Ürün ve Fiyatlar | Ürün ve fiyatlar     | Saha için aktif katalog ve PDF fiyat listesi (okuma)    |
| Siparişler  | Siparişler       | Sipariş taslakları   | Durum ve tutar görünümü                                 |
| Formlar     | Formlar          | Saha formları        | Aktif şablonlar ve gönderimler                          |
| Belgeler    | Belgeler         | Belgeler             | Dosya ve zararlı yazılım tarama durumu                  |
| KVKK        | KVKK             | KVKK ve veri hakları | Rıza, dışa aktarma ve silme talebi                      |
| Güvenlik    | Hesap Güvenliği  | Menü                 | Tüm cihazlardan çıkış                                   |

## Yalnız mobilde bulunan işlevler

- **Saha modu** — kullanıcının başlattığı vardiya boyunca yakınlık hatırlatması.
  Webde karşılığı yoktur; cihaz konumu gerektirir. Bkz. ADR-0006.
- **Müşteri konumunu sahada sabitleme** — müşterinin kapısındayken koordinatı
  kaydeder ve adresten üretilen tahmini ezer.

## Yalnız web yönetim alanında kalan işlevler

- Organizasyon yapısı, ekip daveti ve rol yönetimi
- Paket, kullanım kotası ve ödeme yönetimi
- Entegrasyon kurulumu ve secret yönetimi
- Toplu müşteri içe aktarma ve geri alma
- PDF fiyat listesi yükleme (sahada yalnız okunur, bkz. ADR-0007)
- PDF/XLSX rapor dışa aktarma ve paylaşım bağlantıları
- Çalışma alanı oluşturma/değiştirme

Bu işlemler saha çalışanına gereksiz yetki vermemek, mağaza ödeme kurallarını
ihlal etmemek ve küçük ekranda hatalı toplu işlem riskini azaltmak için webde
tutulur. Mobilde bu alanlara satın alma veya yönetici CTA'sı eklenmez.

## Yayın kapısı

Mobil mağaza build'i alınmadan önce Flutter analizi, tüm mobil testler, web
TypeScript/lint/test/build kontrolleri ve gerçek cihazdaki temel akış testi
geçmelidir. OpenAI kredisi olmadan kartvizit OCR ve ziyaret AI özeti uçtan uca
başarılı sayılamaz.
