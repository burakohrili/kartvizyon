# Kapalı test hata kaydı

Kapalı test süresince bulunan her hata buraya yazılır. Amaç, düzeltmeleri
biriktirip **tek bir yayın build'i** ile mağazaya çıkmaktır; her düzeltme için
ayrı build alınmaz.

Kaynaklar: Sentry (`kartvizyon-flutter`, `kartvizyon-web`), testçi bildirimi,
kendi denetimlerimiz.

## Nasıl kaydedilir

Her satır şunları taşır: **ne görüldü**, **neden oldu**, **nerede düzeltildi**,
**build gerekiyor mu**. Sentry'den gelen kayıtlarda olay kimliği ve etkilenen
sürüm de yazılır — hangi build'de düzeldiğini sonradan doğrulayabilmek için.

Bir hata "kapandı" sayılmaz; **yayınlandı** sayılır. Yayınlandığı build
numarası yazılmadan satır kapatılmaz.

## Yayına çıkmayı bekleyenler

Aşağıdakiler `main` dalında düzeltildi ama henüz mağazaya giden bir build
içinde değil.

| Tarih  | Ne görüldü                                                                                          | Neden                                                                                                                                                                                                                                                   | Düzeltme  | Build |
| ------ | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----- |
| 19 Ağu | `İşlem tamamlanamadı. (HTTP 504)` — Sentry `e5c8e9bb`, `/api/session`, Android 11, sürüm `1.0.0+42` | Uçta zaman aşımı yoktu; Supabase yavaşlayınca işlev platformca kesildi ve **gövdesiz** 504 döndü. İstemci gövdesiz hatada anlamsız metne düşüyordu. Ayrıca uç her ekran açılışında çağrılıyordu, yani bir yavaşlama tek ekranı değil hepsini kırıyordu. | `be33441` | evet  |

## Yayınlananlar

| Tarih  | Ne görüldü                                                                      | Neden                                                                                                                                                                                                                                                  | Düzeltme  | Build                |
| ------ | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | -------------------- |
| 20 Ağu | Kartvizit taraması adresi hiç okumuyor                                          | Çıkarma şemasında `address` alanı yoktu; modele sorulmuyordu bile. Adres olmayınca koordinat da olmuyor ve müşteri haritadan ve yakınlık hatırlatmalarından tamamen düşüyordu.                                                                         | `5996ef2` | Android 43 / iOS 50  |
| 19 Ağu | Uygulama giriş ekranını hiç göstermiyor, her ekran `Oturum gerekli. (HTTP 401)` | Yönlendirici girişli olup olmadığına açılışta bir kez karar veriyordu. Supabase oturumu cihazda kalıcı olduğu için ölü oturumla açılan uygulama kendini girişli sanıyordu; giriş ekranına, dolayısıyla Google/Apple düğmelerine hiçbir yol kalmıyordu. | `c1f5e98` | Android 43 / iOS 50  |
| 19 Ağu | Harita ekranındayken alt çubukta "Daha fazla" seçili görünüyor                  | `/map` sekme listesinde yok, `switch` varsayılana düşüyordu                                                                                                                                                                                            | `54f32b3` | Android 43 / iOS 50  |
| 19 Ağu | Oturumsuz ziyaretçi sahte verilerle dolu bir uygulama görüyor, girişe yol yok   | Korumalı sayfaların hepsi oturum yoksa demo içeriğe düşüyordu; bir kısmında uyarı vardı, `settings/team`'de hiç yoktu ve hiçbirinde giriş bağlantısı yoktu                                                                                             | `3d42243` | web (build gerekmez) |
| 18 Ağu | Test kullanıcıları "hiçbir özellik çalışmıyor" diyor                            | `0022` migration'ı uygulanmamıştı; kod `companies.location_source` seçiyordu ve müşteri uçları 500 dönüyordu. `/api/health` şema kaymasını görmediği için panolar yeşil kalıyordu.                                                                     | `c2c3a7f` | sunucu tarafı        |
| 18 Ağu | Aşağı çekip yenileme uygulamayı çökertiyor                                      | `RefreshIndicator.onRefresh` içinden fırlatılan hata Flutter tarafından yakalanmıyor                                                                                                                                                                   | `c6221a1` | Android 43 / iOS 50  |
| 18 Ağu | Sesli not gönderilmiyor, "bağlantı gelince gönderilecek" yazıp orada kalıyor    | Multipart parçası `application/octet-stream` olarak beyan ediliyordu; sunucu 415 dönüyor ve 415 kalıcı hata sayıldığı için kayıt kuyrukta sonsuza kadar kalıyordu                                                                                      | `5077426` | Android 43 / iOS 50  |
| 18 Ağu | İlk müşteri kaydında `Geçersiz istek.`                                          | `website` alanı tam URL istiyordu; `firma.com` reddediliyordu                                                                                                                                                                                          | `66d1306` | Android 43 / iOS 50  |
| 18 Ağu | Müşteri ekleme ekranı boş kutu olarak açılıyor                                  | Klavye boşluğu iki kez ekleniyordu                                                                                                                                                                                                                     | —         | Android 43 / iOS 50  |

## Düzeltilmeyi bekleyenler

Şu an boş.

## Geçersiz giriş bağlantısı çökmesi (düzeltildi, yayını bekliyor)

**Geçersiz giriş bağlantısı uygulamayı çökertiyordu** — 21 Ağu, sürüm
`1.0.0+41`, iki ayrı olay:

- Sentry `7618402c` — `otp_expired` / `access_denied`, Huawei RNE-L21, Android 8
- Sentry `4e9d9c26` — `bad_code_verifier`, Huawei ANE-LX1, Android 9

İkisi de `level=fatal`, `handled=no`. Zincir şu: `supabase_flutter`
`_handleDeeplink` içinde hatayı yakalayıp `notifyException`'a veriyor, o da
`onAuthStateChange` akışına **stream hatası** olarak ekliyor. Bizim
dinleyicimizde ([login_screen.dart:40](../apps/mobile/lib/features/auth/login_screen.dart))
`onError` olmadığı için hata zone'un yakalanmamış hata yoluna düşüyor ve
uygulama kapanıyor.

Bağlantının geçersiz olması normal bir kullanıcı durumudur; çökme değildir.
Kullanıcı "bağlantının süresi dolmuş, yenisini gönderin" görmelidir.

Bağlantının neden geçersiz olduğu iki olayda farklı:

- `otp_expired`: bağlantı süresi dolmuş ya da daha önce kullanılmış. Supabase
  doğrulama bağlantıları kısa ömürlü ve tek kullanımlıktır.
- `bad_code_verifier`: PKCE doğrulayıcısı eşleşmiyor. Bağlantı başka cihazda
  açıldığında, uygulama silinip kurulduğunda, aynı bağlantıya ikinci kez
  tıklandığında, ilk mail açılmadan ikinci bağlantı istendiğinde (yeni
  doğrulayıcı eskisini ezer) veya e-posta güvenlik tarayıcısı bağlantıyı önden
  açıp kodu tükettiğinde olur.

Mağaza incelemesi açısından da riskliydi: incelemeci doğrulama bağlantısına geç
tıklarsa uygulama gözünün önünde çökerdi.

**Kapı e-postaya özel değil.** Google ve Apple girişi de aynı callback
adresinden (`app.kartvizyon.mobile://login-callback`) döndüğü için tarayıcıda
"vazgeç" demek veya uygulamanın arka planda öldürülmesi de aynı çökmeyi
üretiyordu. Yani **her giriş yolu** aynı riski taşıyordu.

Düzeltme `b231ab7`: dinleyiciye `onError` eklendi, bilinen hata kodları
kullanıcıya ne yapacağını söyleyen Türkçe metne çevrildi, ve tarayıcıdan
sonuçsuz dönüldüğünde ekranda asılı kalan "giriş ekranı açılıyor…" mesajı
temizleniyor. `apps/mobile/test/auth_error_test.dart` dinleyicinin `onError`
olmadan kurulmasını engelliyor.

## Açık kalanlar

| Konu                                              | Durum                                                                                     |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Supabase Free planda                              | 504'ün kök nedeni buydu. Pro'ya geçiş bu tür yavaşlamaları azaltır; ürün kararı bekliyor. |
| Görevler çevrimdışı çalışmıyor                    | Görev oluşturma ve tik doğrudan API'ye gidiyor, offline kuyruğu kullanmıyor.              |
| Tamamlanan görevler listeden düşmüyor, filtre yok | Görev sayısı arttıkça liste kullanılmaz hale gelir.                                       |

## Yayın öncesi kapı

Tek build ile çıkmadan önce:

1. Bu dosyada "yayına çıkmayı bekleyen" satır kalmamalı.
2. `npm run check` tam yeşil.
3. Android kapalı test 14 gün / 12 kullanıcı şartı tamamlanmış olmalı.
4. Apple beta incelemesi geçmiş olmalı.
5. Mağaza beyanları koda karşı doğru olmalı (`docs/STORE_RELEASE.md`).
