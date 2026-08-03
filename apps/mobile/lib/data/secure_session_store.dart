import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  const SecureSessionStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  static const _accessToken = 'supabase_access_token';
  static const _refreshToken = 'supabase_refresh_token';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessToken, value: accessToken);
    await _storage.write(key: _refreshToken, value: refreshToken);
  }

  Future<({String accessToken, String refreshToken})?> read() async {
    final values = await Future.wait([
      _storage.read(key: _accessToken),
      _storage.read(key: _refreshToken),
    ]);
    if (values.any((value) => value == null)) return null;
    return (accessToken: values[0]!, refreshToken: values[1]!);
  }

  Future<void> clear() => _storage.deleteAll();
}
