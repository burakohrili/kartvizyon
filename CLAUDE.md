# KartVizyon AI geliştirme anayasası

Ürünün bağlayıcı ana brifi kullanıcı tarafından sağlanan kapsam belgesidir. Bu depoda yapılan her değişiklik şu sınırları korur:

- Ürün, kartvizit arşivi ya da tam kapsamlı CRM/ERP değildir; saha müşteri hafızası ve ziyaret yönetimidir.
- AI çıktıları `needs_review` durumunda başlar; kullanıcı onayı olmadan kurumsal kayda veya yönetici akışına girmez.
- Kurumsal sorgular `organizationId` ile izole edilir ve yetkilendirme testi olmadan tamamlanmış sayılmaz.
- Offline kullanım temel gereksinimdir. AI çalışmasa dahi manuel ziyaret kaydı devam eder.
- Ham ses varsayılan olarak yöneticilere açılmaz; sürekli GPS takibi yapılmaz.
- Türkçe ana ürün dilidir. Kritik işlemler audit log üretmeye elverişli olmalıdır.
- Kapsam genişlemesi önce `docs/product/decisions/` altında ADR gerektirir.
- Şema değişikliği migration ve rollback; AI sözleşmesi Zod/JSON Schema doğrulaması gerektirir.

Uygulama sırası ve kabul kriterleri için `docs/ROADMAP.md` dosyasını kullanın.
