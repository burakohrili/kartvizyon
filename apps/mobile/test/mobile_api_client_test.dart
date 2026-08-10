import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  test('401 sonrasında oturumu yenileyip isteği bir kez tekrarlar', () async {
    final authorizationHeaders = <String?>[];
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      accessTokenProvider: () async => 'expired-token',
      refreshAccessToken: () async => 'fresh-token',
      client: MockClient((request) async {
        authorizationHeaders.add(request.headers['authorization']);
        if (authorizationHeaders.length == 1) {
          return http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401);
        }
        return http.Response(jsonEncode({'data': <Object>[]}), 200);
      }),
    );

    final response = await client.get('/api/customers');

    expect(response, {'data': <Object>[]});
    expect(authorizationHeaders, [
      'Bearer expired-token',
      'Bearer fresh-token',
    ]);
  });

  test('yenileme başarısızsa 401 anlamlı hata olarak döner', () async {
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      accessTokenProvider: () async => 'expired-token',
      refreshAccessToken: () async => null,
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401),
      ),
    );

    expect(
      () => client.get('/api/customers'),
      throwsA(
        isA<MobileApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', 'Oturum gerekli.'),
      ),
    );
  });
}
