import 'dart:async';
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

  test('yanıt gelmezse sonsuza kadar beklemez', () async {
    // Zaman aşımı hiç yoktu: takılan istek, tamamen hareketsiz görünen bir
    // ekran olarak sonsuza kadar bekliyordu.
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      timeout: const Duration(milliseconds: 40),
      client: MockClient((_) => Completer<http.Response>().future),
    );

    await expectLater(
      client.get('/api/customers'),
      throwsA(
        isA<MobileApiException>()
            .having((error) => error.statusCode, 'statusCode', 408)
            .having(
              (error) => error.message,
              'message',
              contains('zaman'),
            ),
      ),
    );
  });

  test('her istek aktif çalışma alanını taşır', () async {
    // Sunucu çalışma alanını çerezden okuyor; mobil istemci çerez
    // göndermediği için "ilk çalışma alanı" geri düşüşüne düşüyordu.
    var workspace = 'workspace-1';
    final seen = <String?>[];
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      workspaceId: () => workspace,
      client: MockClient((request) async {
        seen.add(request.headers['x-kartvizyon-workspace']);
        return http.Response(jsonEncode({'data': <Object>[]}), 200);
      }),
    );

    await client.get('/api/opportunities');
    workspace = 'workspace-2';
    await client.get('/api/opportunities');

    // Değer kopyalanmaz; oturum bağlamı değiştiğinde başlık da değişmeli.
    expect(seen, ['workspace-1', 'workspace-2']);
  });

  test('kurtarılamayan oturum bildirilir', () async {
    // Yönlendirici açılışta bir kez `authenticated` hesaplıyordu ve bunu
    // yalnız menüden çıkış değiştiriyordu. Supabase oturumu cihazda kalıcı
    // olduğu için ölü oturumla açılan uygulama kendini girişli sanıyor, her
    // istek 401 dönüyor ve kullanıcı "Oturum gerekli. (HTTP 401)" ekranında
    // kilitleniyordu; giriş ekranına, yani Google ve Apple düğmelerine,
    // hiçbir yol kalmıyordu.
    var expired = 0;
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      accessTokenProvider: () async => 'expired-token',
      refreshAccessToken: () async => null,
      onSessionExpired: () => expired += 1,
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401),
      ),
    );

    await expectLater(
      client.get('/api/customers'),
      throwsA(isA<MobileApiException>()),
    );
    expect(expired, 1);
  });

  test('taze token da 401 alıyorsa oturum bildirilir', () async {
    var expired = 0;
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      accessTokenProvider: () async => 'expired-token',
      refreshAccessToken: () async => 'fresh-token',
      onSessionExpired: () => expired += 1,
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401),
      ),
    );

    await expectLater(
      client.get('/api/customers'),
      throwsA(isA<MobileApiException>()),
    );
    expect(expired, 1);
  });

  test('başarılı istek oturumu ölü saymaz', () async {
    var expired = 0;
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      accessTokenProvider: () async => 'expired-token',
      refreshAccessToken: () async => 'fresh-token',
      onSessionExpired: () => expired += 1,
      client: MockClient((request) async {
        if (request.headers['authorization'] == 'Bearer expired-token') {
          return http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401);
        }
        return http.Response(jsonEncode({'data': <Object>[]}), 200);
      }),
    );

    await client.get('/api/customers');
    expect(expired, 0);
  });

  test('gövdesiz ağ geçidi hatası ne yapılacağını söyler', () async {
    // 502/503/504 gövdesi boştur; okunacak bir `error` alanı yoktur ve
    // kullanıcı "İşlem tamamlanamadı. (HTTP 504)" görüyordu. 19 Ağustos
    // 2026'da `/api/session` bir kez 504 döndü ve testçiye tam olarak bu
    // göründü.
    for (final status in [502, 503, 504]) {
      final client = MobileApiClient(
        baseUrl: Uri.parse('https://app.kartvizyon.app'),
        sessions: const _EmptySessionStore(),
        client: MockClient((_) async => http.Response('', status)),
      );
      await expectLater(
        client.get('/api/session'),
        throwsA(
          isA<MobileApiException>().having(
            (error) => error.message,
            'message',
            contains('tekrar deneyin'),
          ),
        ),
      );
    }
  });

  test('sunucu kendi mesajını yazdıysa o korunur', () async {
    final client = MobileApiClient(
      baseUrl: Uri.parse('https://app.kartvizyon.app'),
      sessions: const _EmptySessionStore(),
      client: MockClient(
        (_) async => http.Response(jsonEncode({'error': 'Kota doldu.'}), 503),
      ),
    );
    await expectLater(
      client.get('/api/customers'),
      throwsA(
        isA<MobileApiException>().having(
          (error) => error.message,
          'message',
          'Kota doldu.',
        ),
      ),
    );
  });
}
