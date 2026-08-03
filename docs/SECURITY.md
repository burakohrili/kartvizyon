# Güvenlik modeli

- Kurumsal veriler çalışma alanı ve organizasyon kapsamında RLS ile izole edilir.
- AI çıktısı `needs_review` durumunda başlar; onaylanmadan rapora, hafızaya veya yönetici akışına girmez.
- Ham ses/transkript yalnızca sahibine açıktır. Belgeler karantinada başlar ve `clean` olmadan indirilemez.
- API/webhook sırlarının yalnızca SHA-256 özeti saklanır ve sır oluşturma yanıtında bir kez gösterilir.
- Rapor tokenları hash’li, süreli ve iptal edilebilirdir.
- Kritik onay, paylaşım, davet, oturum, sipariş, entegrasyon ve KVKK işlemleri audit kaydı üretir.
- İstekler kullanıcı + rota bazında atomik veritabanı sayacıyla sınırlandırılır.
- Konum yalnızca açık kullanıcı eylemiyle alınır; arka planda sürekli GPS yoktur.

Production anahtarları loglanmamalı veya istemci paketine gömülmemelidir.

## Production servis sınırları

- Vercel yalnız public web/API ve authenticated cron dispatcher’dır; ClamAV ayrı container’da çalışır.
- Tarayıcıya verilen storage URL’si 5 dakika geçerlidir. Worker indirilen dosyanın 20 MB sınırını ve SHA-256 özetini tekrar doğrular.
- Tarama işleri `FOR UPDATE SKIP LOCKED` ile atomik sahiplenilir; 15 dakika takılan işler en fazla üç kez denenir.
- Resend anahtarı sending-only yetkilidir; mailbox veya domain yönetim yetkisi yoktur.
- Mobil release, debug anahtarıyla üretilemez. Apple/Google/Codemagic kimlikleri KartVizyon bundle/application ID’sine scope edilir.
- Public pazarlama sayfası authenticated uygulamadan hostname ile ayrılır; API/RLS güvenliği hostname’e güvenmez.
- Hesap silmede kişisel workspace cascade silinir; kurumsal kayıtlardaki kullanıcı yabancı anahtarları `ON DELETE SET NULL` ile anonimleşir. Aktif organizasyon sahibi silinemez, önce sahiplik devri gerekir.
- Ham ses/transkript ve kullanıcıya özel AI işleri `ON DELETE CASCADE`; audio, belge ve privacy export storage nesneleri Auth kullanıcısı silinmeden önce worker tarafından kaldırılır.

## Log ve Sentry veri minimizasyonu

Sentry ve operasyon loglarına parola, access/refresh token, Supabase service key, OpenAI/Resend anahtarı, tam e-posta, ses, transkript, belge veya AI prompt gövdesi eklenmez. Kullanıcı kimliği gerektiğinde tek yönlü pseudonymous ID kullanılır. Replay açılırsa metin ve medya varsayılan olarak maskelenir.
