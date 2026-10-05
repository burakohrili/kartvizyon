import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('sandbox oturumu canlı tokenları okuyamaz veya silemez', () async {
    FlutterSecureStorage.setMockInitialValues({
      'supabase_access_token': 'production-access',
      'supabase_refresh_token': 'production-refresh',
      'unrelated-secret': 'keep',
    });
    const live = SecureSessionStore();
    const sandbox = SecureSessionStore.sandbox();
    expect(await sandbox.read(), isNull);
    await sandbox.save(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
    );
    expect((await live.read())?.accessToken, 'production-access');
    expect((await sandbox.read())?.accessToken, 'test-access');
    await sandbox.clear();
    expect(await sandbox.read(), isNull);
    expect((await live.read())?.accessToken, 'production-access');
    await live.clear();
    expect(await live.read(), isNull);
    expect(
      await const FlutterSecureStorage().read(key: 'unrelated-secret'),
      'keep',
    );
  });
}
