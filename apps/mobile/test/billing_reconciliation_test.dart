import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/core/billing_reconciliation.dart';

void main() {
  test(
    'sunucu bilinmiyor, salt okunur veya deneme ise premium doğrulanmaz',
    () {
      expect(serverPremiumConfirmed(null), isFalse);
      expect(serverPremiumConfirmed({}), isFalse);
      expect(
        serverPremiumConfirmed({'readOnly': true, 'trialActive': false}),
        isFalse,
      );
      expect(
        serverPremiumConfirmed({'readOnly': false, 'trialActive': true}),
        isFalse,
      );
      expect(
        serverPremiumConfirmed({'readOnly': false, 'trialActive': false}),
        isTrue,
      );
    },
  );

  String result({
    bool store = true,
    bool server = false,
    bool sandbox = false,
    bool restoring = true,
    String url = 'https://sandbox.example.test',
  }) => billingReconciliationMessage(
    restoring: restoring,
    storeActive: store,
    serverConfirmed: server,
    sandboxPurchase: sandbox,
    apiBaseUrl: url,
  );

  test(
    'mağaza aktif olsa bile sunucu açılmadan geri yükleme başarılı denmez',
    () {
      expect(result(), contains('henüz açılmadı'));
      expect(result(), isNot(contains('geri yüklendi')));
      expect(result(restoring: false), contains('Tekrar satın almayın'));
    },
  );
  test('canlı sunucudaki sandbox satın alması açıkça ayrılır', () {
    for (final host in ['app.kartvizyon.app', 'kartvizyon.app']) {
      expect(
        result(sandbox: true, server: true, url: 'https://$host'),
        contains('Sandbox satın almaları canlı erişimi açmaz'),
      );
    }
  });
  test('iki taraf doğrulanırsa sandbox sunucusunda başarı bildirilir', () {
    expect(
      result(server: true, sandbox: true),
      contains('sunucu erişiminiz doğrulandı'),
    );
    expect(
      result(server: true, restoring: false),
      contains('Premium etkinleşti'),
    );
  });
  test(
    'sunucuda hak olsa bile mağazada aktif satın alma yoksa restore başarısızdır',
    () {
      expect(
        result(store: false, server: true),
        contains('aktif satın alma bulunamadı'),
      );
    },
  );
}
