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
