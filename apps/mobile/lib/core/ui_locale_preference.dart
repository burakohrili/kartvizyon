import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class UiLocalePreferenceStore {
  Future<String?> read();
  Future<void> write(String languageCode);
}

class SecureUiLocalePreferenceStore implements UiLocalePreferenceStore {
  SecureUiLocalePreferenceStore([
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  ]) : _storage = storage;

  static const _key = 'kartvizyon_ui_locale';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String languageCode) =>
      _storage.write(key: _key, value: languageCode);
}
