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
| Takvim      | Takvim           | Takvim               | Listeleme ve yeni planlı ziyaret oluşturma              |
| Aktivite    | Aktivite         | Aktivite             | Son onaylanan saha ziyaretleri                          |
| Raporlar    | Raporlar         | Rapor özeti          | Müşteri, onay, inceleme ve açık görev göstergeleri      |
| Bildirimler | Bildirimler      | Bildirimler          | Listeleme ve okundu işaretleme                          |
| Fırsatlar   | Fırsatlar        | Fırsatlar            | Oluşturma, listeleme ve aşama güncelleme                |
| Ürünler     | Ürün ve Fiyatlar | Ürün ve fiyatlar     | Aktif katalog, ürün ekleme ve fiyat listesi okuma       |
| Siparişler  | Siparişler       | Sipariş taslakları   | Taslak oluşturma ve durum geçişleri                     |
| Formlar     | Formlar          | Saha formları        | Şablon oluşturma, doldurma ve gönderimleri görme        |
| Belgeler    | Belgeler         | Belgeler             | Fotoğraf yükleme, tarama durumu ve temiz belgeyi açma   |
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
- PDF/DOCX toplu belge ve fiyat listesi yönetimi (mobil tekil belge fotoğrafı yükler)
- PDF/XLSX rapor dışa aktarma ve paylaşım bağlantıları
- Çalışma alanı oluşturma/değiştirme

Bu işlemler saha çalışanına gereksiz yetki vermemek, mağaza ödeme kurallarını
ihlal etmemek ve küçük ekranda hatalı toplu işlem riskini azaltmak için webde
tutulur. Mobilde bu alanlara satın alma veya yönetici CTA'sı eklenmez.

Firma kayıtlarında yasal `name` korunur; isteğe bağlı `display_name` mobil
listelerde ve aramalı seçim pencerelerinde kısa saha adı olarak kullanılır.
Müşteri uç noktası sayfalıdır; mobil liste ve görev/ziyaret seçicileri kayıt
sayısı büyüdüğünde arama ve devam sayfalarıyla çalışır.

## Yayın kapısı

Mobil mağaza build'i alınmadan önce Flutter analizi, tüm mobil testler, web
TypeScript/lint/test/build kontrolleri ve gerçek cihazdaki temel akış testi
geçmelidir. OpenAI kredisi olmadan kartvizit OCR ve ziyaret AI özeti uçtan uca
başarılı sayılamaz.
