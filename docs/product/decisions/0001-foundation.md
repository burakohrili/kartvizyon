# ADR-0001: İlk teknik temel

Durum: Kabul edildi

## Karar

Web için Next.js App Router, ortak TypeScript sözleşmeleri için Zod ve npm workspaces kullanılacaktır. Kalıcı veri katmanı PostgreSQL/Supabase RLS olacak; bu teslimatta dış servis kimliği gerektiren kurulum ertelenmiştir.

## Gerekçe

Boş depoda önce bağımsız test edilebilen ürün kuralları ve çalışan kullanıcı yüzeyi oluşturmak, altyapı sağlayıcısı seçimini geri döndürülebilir tutar. Mobil uygulama brifte belirtildiği gibi Flutter olacaktır ve aynı JSON sözleşmelerini OpenAPI üzerinden tüketecektir.

## Sonuçlar

- Domain durumları istemci metinlerinden ayrı tutulur.
- Kurumsal erişim tenant bağlamı olmadan reddedilir.
- Harici veritabanı ve kimlik bilgileri eklenmeden demo çalışabilir.
