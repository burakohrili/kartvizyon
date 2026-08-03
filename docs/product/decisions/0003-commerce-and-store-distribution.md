# ADR-0003: Ticaret modeli ve mağaza dağıtımı

- Durum: Kabul edildi
- Tarih: 2026-08-03

## Bağlam

KartVizyon hem bireysel saha profesyonellerine hem kurumsal satış organizasyonlarına
satılacaktır. Tahsilatı Türkiye'de kurulmuş bir işletme (Noesis Social - Burak OHRİLİ)
yapacaktır. Stripe'ın resmi ülke listesinde Türkiye bulunmadığı için Stripe'a bağımlı
bir plan kurulamaz.

Mobil uygulamada uygulama içi satın alma (IAP) açılırsa Apple ve Google dijital abonelik
satışında kendi ödeme sistemlerini zorunlu tutar ve %15-30 komisyon alır; ayrıca
entitlement senkronizasyonu, iade akışı ve ayrı bir mağaza inceleme yüzeyi gerekir.

## Karar

1. **Tahsilat sağlayıcısı iyzico'dur.** Web aboneliği iyzico Subscription ile kurulur;
   para birimi TRY, periyot aylık ve yıllık.
2. **Bireysel ve kurumsal plan birlikte kurulur.** İkisi de aynı entitlement modelini
   kullanır; fark plan limitleri ve rol yetkilerindedir.
3. **Satın alma yalnızca web üzerinde yapılır** — `app.kartvizyon.app`. Bu, hem bireysel
   hem kurumsal için geçerlidir.
4. **Mobil uygulamada satın alma, fiyat CTA'sı veya dış ödeme bağlantısı bulunmaz.**
   Mobil yalnızca mevcut planı ve kotayı gösterir. Plan yönetimi gerektiğinde kullanıcıya
   "Planınız web üzerinden yönetiliyor" bilgisi verilir; tıklanabilir ödeme yönlendirmesi konmaz.
5. **Uygulama içi satın alma ilk sürümde kapsam dışıdır.** İhtiyaç doğarsa ayrı bir ADR ile
   Apple IAP + Google Play Billing (ve tercihen RevenueCat entitlement katmanı) değerlendirilir.

## Gerekçe

- Apple App Review Guidelines 3.1.3, ücretli web hizmetinin yardımcı uygulamasında IAP
  zorunluluğuna istisna tanır; ancak uygulama içinde dış ödemeye yönlendiren CTA bulunmamalıdır.
- Google Play ödeme politikası, uygulama içinde dijital abonelik satılırsa Play Billing'i zorunlu tutar.
  Mobil "consumption-only" konumlandırıldığında bu zorunluluk doğmaz.
- Bu model %15-30 komisyondan tamamen kaçınır ve mağaza inceleme riskini azaltır.
- Tek tahsilat noktası; fatura, iade, vergi ve entitlement mantığının tek yerde kalmasını sağlar.

## Sonuçlar

- `settings/billing` yüzeyi mobilde salt-okunur kalmalıdır; satın alma butonu eklenmesi bu ADR'yi ihlal eder.
- iyzico webhook imza doğrulaması ve idempotent entitlement güncellemesi zorunludur.
- Fatura ve iade akışı Türkiye mevzuatına göre tasarlanmalıdır.
- Mağaza inceleme notlarında uygulamanın ödeme içermediği açıkça belirtilmelidir.
- İleride bireysel kullanıcı için mobil IAP istenirse bu ADR yerine yeni bir ADR yazılır.
