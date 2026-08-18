# Fatura, iptal ve iade süreci

Bu belge KartVizyon aboneliklerinin faturalandırma ve iade işletim sürecidir.
Fiyatlar ADR-0005'te, tahsilat mimarisi ADR-0003 ve ADR-0004'tedir.
**Ödeme sağlayıcısı henüz bağlanmadığı için hiçbir tahsilat yapılmamaktadır;**
bu süreç iyzico canlıya alındığı gün yürürlüğe girer.

## Satıcı bilgileri

- Unvan: Noesis Social - Burak OHRİLİ
- Vergi dairesi / VKN: Ege Vergi Dairesi · 6360302767
- Adres: Gazi Osmanpaşa Mah. 5499/1 Sok. No:9 Bornova / İzmir
- E-posta: `kartvizyonapp@gmail.com` (kalıcı adres `support@kartvizyon.app` mailbox alındığında geçerli olur)
- Telefon: +90 532 744 94 34
- KEP: **kullanıcıdan alınacak** — bkz. `docs/IYZICO_APPLICATION_READINESS.md`

## Fatura

| Konu            | Kural                                                                                    |
| --------------- | ---------------------------------------------------------------------------------------- |
| Belge türü      | e-Arşiv fatura (bireysel) / e-Fatura (mükellef kurumsal alıcı)                           |
| Düzenleme anı   | Tahsilatın başarıyla tamamlandığı gün                                                    |
| Gönderim        | Hesap e-postasına PDF; ayrıca abonelik ekranından indirilebilir                          |
| Para birimi     | TRY                                                                                      |
| KDV             | %20 (yürürlükteki oran esas alınır; oran değişirse ekranda gösterilen tutar güncellenir) |
| Fiyat gösterimi | Sitede KDV hariç liste fiyatı, ödeme ekranında KDV dâhil toplam                          |
| Kurumsal alıcı  | Unvan, VKN/TCKN ve vergi dairesi satın alma sırasında alınır                             |
| Saklama         | Mevzuattaki asgari süre boyunca saklanır                                                 |

## Yenileme ve iptal

- Abonelik, satın alma ekranında açıklanan dönemde otomatik yenilenir.
- Yenileme tarihinden önce hesap e-postasına hatırlatma gönderilir.
- İptal, abonelik ekranından veya destek kanalından yazılı talep ile yapılır.
- İptal **mevcut ücretli dönemin sonunda** yürürlüğe girer; kalan gün için
  hizmet kesilmez ve sonraki dönem ücreti alınmaz.
- İptal sonrası veri silinmez; hesap ücretsiz katman limitleriyle çalışmaya
  devam eder (ADR-0005).

## Deneme süresi

- Her yeni kişisel çalışma alanı 14 gün tam erişimli denemeyle başlar.
- Deneme sırasında kart bilgisi istenmez ve tahsilat yapılmaz.
- Süre dolduğunda `expire-trials` cron'u planı ücretsiz katmana düşürür.

## İade

| Durum                                    | İşlem                                                                     |
| ---------------------------------------- | ------------------------------------------------------------------------- |
| Çifte tahsilat                           | Fazla çekilen tutar tamamen iade edilir                                   |
| Yetkisiz / hatalı işlem                  | İnceleme sonrası tam iade                                                 |
| Hizmetin hiç etkinleşmemesi              | Tam iade                                                                  |
| Ayıplı ifa                               | 6502 sayılı Kanun'daki seçimlik haklar uygulanır                          |
| Kullanıcı kaynaklı dönem ortası vazgeçme | Dönem sonuna kadar hizmet sürer; kalan dönem için iade zorunluluğu yoktur |

- İade, ödemenin yapıldığı yönteme ve karta gönderilir.
- Bankanın hesaba yansıtma süresi ayrıca işler ve KartVizyon'un kontrolünde değildir.
- Tüketicinin emredici mevzuattan doğan cayma ve seçimlik hakları saklıdır.
- Talepler `kartvizyonapp@gmail.com` adresine işlem tarihi ve hesap e-postasıyla
  iletilir. **Kart numarası, CVV, parola veya doğrulama kodu istenmez ve gönderilmemelidir.**

## Talep işleme hedefleri

| Adım                           | Hedef süre                             |
| ------------------------------ | -------------------------------------- |
| Talebin alındığının teyidi     | 1 iş günü                              |
| İnceleme sonucu bildirimi      | 5 iş günü                              |
| Onaylanan iadenin başlatılması | 10 iş günü (mevzuat üst sınırı içinde) |

## Kayıt ve denetim

- Sipariş onayı, ön bilgilendirme metni, sözleşme onayı ve ödeme sonucu
  `audit_logs` üzerinde kayıt altına alınır.
- Ödeme sağlayıcısından gelen bildirimler idempotent işlenir; aynı işlem iki kez
  kredi veya iade üretemez (`workspace_ai_topups` sağlayıcı referansı üzerinde
  benzersiz indeks bulunur).
- Ödeme sağlayıcı gövdesinde gelen tutar/plan bilgisine istemciden gelen veriye
  güvenilmeden sunucu tarafında doğrulanır.

## Uyuşmazlık

Tüketiciler, yürürlükteki parasal sınırlar kapsamında Tüketici Hakem
Heyetlerine veya Tüketici Mahkemelerine başvurabilir. Hukuki metinler tahsilat
açılmadan önce Türkiye tüketici/e-ticaret hukukunda uzman bir profesyonel
tarafından gözden geçirilmelidir.
