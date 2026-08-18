# KartVizyon AI geliştirme anayasası

Ürünün bağlayıcı ana brifi kullanıcı tarafından sağlanan kapsam belgesidir. Bu depoda yapılan her değişiklik şu sınırları korur:

- Ürün, kartvizit arşivi ya da tam kapsamlı CRM/ERP değildir; saha müşteri hafızası ve ziyaret yönetimidir.
- AI çıktıları `needs_review` durumunda başlar; kullanıcı onayı olmadan kurumsal kayda veya yönetici akışına girmez.
- Kurumsal sorgular `organizationId` ile izole edilir ve yetkilendirme testi olmadan tamamlanmış sayılmaz.
- Offline kullanım temel gereksinimdir. AI çalışmasa dahi manuel ziyaret kaydı devam eder.
- Ham ses varsayılan olarak yöneticilere açılmaz; sürekli GPS takibi yapılmaz. Saha modu bu ilkenin istisnası değildir: kullanıcı başlatır, görünür çalışır, kendiliğinden kapanır ve kullanıcı konumu saklanmaz (ADR-0006).
- Türkçe ana ürün dilidir. Kritik işlemler audit log üretmeye elverişli olmalıdır.
- Kapsam genişlemesi önce `docs/product/decisions/` altında ADR gerektirir.
- Şema değişikliği migration ve rollback; AI sözleşmesi Zod/JSON Schema doğrulaması gerektirir.

Uygulama sırası ve kabul kriterleri için `docs/ROADMAP.md` dosyasını kullanın.

## Production kararları

- İşletme: Noesis Social - Burak OHRİLİ, Gazi Osmanpaşa Mah. 5499/1 Sok. No:9 Bornova / İzmir, Ege Vergi Dairesi VKN 6360302767, telefon +90 532 744 94 34.
- Bireysel ve kurumsal satış birlikte desteklenecektir; ödeme entegrasyonu ayrı karar tamamlanana kadar kapalıdır.
- Public yüzey `kartvizyon.app`, authenticated uygulama `app.kartvizyon.app`, mobil kimlik `app.kartvizyon.mobile`.
- Harici production kararları için ADR-0002; mobil UX için `docs/DESIGN.md`; mağaza kapısı için `docs/STORE_RELEASE.md` bağlayıcıdır.
- Mağaza başlık/açıklama/reviewer notu için `docs/STORE_LISTING_TR.md` kullanılır; gerçek uygulama kapsamını aşan pazarlama iddiası eklenmez.
- Başka Apple/Google uygulamalarının sertifika, App ID, provisioning profile, service account veya keystore’u KartVizyon’da kullanılmaz.
