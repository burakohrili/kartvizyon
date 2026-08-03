# ADR-0002: Production servisleri ve yayın yüzeyleri

Durum: Kabul edildi · 3 Ağustos 2026

## Bağlam

ADR-0001 dış servisleri erteliyordu. Supabase, OpenAI ve Vercel artık production altyapısının parçasıdır; `kartvizyon.app` satın alınmış, Resend SMTP ve harici ClamAV tarayıcı mimarisi seçilmiştir.

## Karar

- Supabase; Auth, PostgreSQL/RLS ve private Storage sağlar.
- OpenAI yalnız sunucu üzerinden transkripsiyon/özet/OCR için çağrılır; sonuçlar kullanıcı onayına tabidir.
- Vercel Next.js web/API ve cron uçlarını barındırır.
- `kartvizyon.app` public pazarlama/yasal yüzey, `app.kartvizyon.app` authenticated uygulama yüzeyidir; aynı deployment hostname rewrite kullanır.
- Resend, `auth.kartvizyon.app` gönderen alanıyla Supabase Auth SMTP sağlar.
- Belgeler private karantinada tutulur; ayrı container içindeki ClamAV sonucu `clean` olmadan okunamaz.
- Sentry web/mobil hata izleme için seçilmiştir; kullanıcı içeriği, ses, transkript ve belge gövdeleri event’e eklenmez.
- Mobil CI/CD Codemagic’dir; KartVizyon imzaları diğer uygulama kimliklerinden ayrıdır.
- Bireysel ve kurumsal satış kesin karardır. Ödeme sağlayıcısı ve mağaza içi satın alma modeli ayrı ADR ile belirlenecektir.

## Sonuçlar

Harici servis kesintisi manuel saha kaydını durdurmaz. Secret’lar yalnız sağlayıcı secret store’larında tutulur. Production kurulumu kod, migration, DNS ve sağlayıcı doğrulaması birlikte tamamlanmadan “hazır” kabul edilmez.
