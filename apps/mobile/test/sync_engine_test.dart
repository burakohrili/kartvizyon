import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';

void main() {
  test('başarılı istek kuyruktan silinmeye uygundur', () {
    expect(classifySyncStatus(200), SyncDisposition.success);
    expect(classifySyncStatus(201), SyncDisposition.success);
  });
  test('oturum ve geçici hata durumlarını ayırır', () {
    expect(classifySyncStatus(401), SyncDisposition.authRequired);
    expect(classifySyncStatus(409), SyncDisposition.retryLater);
    expect(classifySyncStatus(503), SyncDisposition.retryLater);
    expect(classifySyncStatus(422), SyncDisposition.permanentFailure);
  });
}
