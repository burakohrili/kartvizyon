import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/features/map/map_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

/// İzni verilmiş, konumu hazır bir cihaz.
class _ReadyGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async =>
      Position(
        latitude: 38.46,
        longitude: 27.21,
        timestamp: DateTime.utc(2026, 8, 18),
        accuracy: 12,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sunucu hatası konum hatası gibi gösterilmez', (tester) async {
    GeolocatorPlatform.instance = _ReadyGeolocator();

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      // Uç gerçekten çağrılsın diye Supabase yapılandırılmış sayılır.
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      sentryDsn: '',
    );
    final services = MobileServices.forTesting(
      config: config,
      database: database,
      sessions: const _EmptySessionStore(),
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: const _EmptySessionStore(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'error': 'Oturum gerekli.'}),
            401,
          ),
        ),
      ),
      sync: SyncEngine(
        database: database,
        sessions: const _EmptySessionStore(),
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );

    await tester.pumpWidget(MaterialApp(home: MapScreen(services: services)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yakınımdakileri bul'));
    await tester.pumpAndSettle();

    // Konum alındı; hata sunucudan geldi. Tek `catch (_)` varken kullanıcı
    // "Konum alınamadı" görüp izinlerle uğraşıyordu.
    expect(find.textContaining('Konum alınamadı'), findsNothing);
    expect(find.text('Oturum gerekli.'), findsOneWidget);
  });
}
