import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Geçersiz giriş bağlantısı uygulamayı çökertmemeli.
///
/// 21 Ağustos 2026'da iki testçide `level=fatal`, `handled=no` çökme oluştu
/// (Sentry `7618402c` — `otp_expired`; `4e9d9c26` — `bad_code_verifier`).
/// Zincir şu: `supabase_flutter` derin bağlantı hatasını yakalayıp
/// `notifyException`'a veriyor, o da `onAuthStateChange` akışına **stream
/// hatası** olarak ekliyor. Dinleyicide `onError` yoksa hata zone'un
/// yakalanmamış hata yoluna düşüyor ve uygulama kapanıyor.
///
/// Kapı e-postaya özel değil: Google ve Apple girişi de aynı callback
/// adresinden döndüğü için tarayıcıda vazgeçmek de buraya düşer. Bu yüzden
/// dinleyici `onError` olmadan bırakılamaz.
void main() {
  final source = File(
    'lib/features/auth/login_screen.dart',
  ).readAsStringSync();

  test('auth akışı dinleyicisi onError olmadan kurulmaz', () {
    final start = source.indexOf('onAuthStateChange.listen(');
    expect(start, greaterThan(-1), reason: 'auth dinleyicisi bulunamadı');
    // Gövde içinde de `);` geçtiği için kapanışa göre değil, çağrının hemen
    // ardındaki pencereye bakılır.
    final listener = source.substring(
      start,
      (start + 400).clamp(0, source.length),
    );
    expect(
      listener.contains('onError:'),
      isTrue,
      reason: 'onError olmadan geçersiz bağlantı uygulamayı çökertir',
    );
  });

  test('bilinen bağlantı hataları kullanıcıya ne yapacağını söyler', () {
    // Sentry'de görülen iki kod da karşılanmalı; aksi halde kullanıcı
    // İngilizce ham mesajı görür.
    for (final code in ['otp_expired', 'access_denied', 'bad_code_verifier']) {
      expect(
        source.contains("'$code'"),
        isTrue,
        reason: '$code için kullanıcıya mesaj yok',
      );
    }
    expect(source.contains('süresi dolmuş'), isTrue);
    expect(source.contains('başka bir cihazda'), isTrue);
  });

  test('tarayıcıdan sonuçsuz dönüş ekranı serbest bırakır', () {
    // `signInWithOAuth` yalnız tarayıcının açıldığını söyler. Kullanıcı
    // vazgeçip döndüğünde "giriş ekranı açılıyor…" yazısı asılı kalıyordu.
    expect(source.contains('didChangeAppLifecycleState'), isTrue);
    expect(source.contains('awaitingOAuth'), isTrue);
  });
}
