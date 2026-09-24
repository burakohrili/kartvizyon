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
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
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

class _DeniedGeolocator extends _ReadyGeolocator {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.deniedForever;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mesafe ve eksik bağlam kullanıcı dilinde gösterilir', () {
    expect(formatNearbyDistance(0.35), '350 m');
    expect(formatNearbyDistance(1.4), '1,4 km');
    expect(formatNearbyDistance(null), 'Mesafe bilinmiyor');
    expect(nearbyVisitLabel({}), 'Henüz ziyaret edilmedi');
    expect(nearbyTaskLabel({}), 'Geciken görev yok');
    expect(nearbyTaskLabel({'overdueTaskCount': 2}), '2 geciken görev');
  });

  testWidgets('konum izni reddi müşteri arama alternatifini gösterir', (
    tester,
  ) async {
    GeolocatorPlatform.instance = _DeniedGeolocator();
    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      supabaseUrl: '',
      supabaseAnonKey: '',
      sentryDsn: '',
    );
    final services = MobileServices.create(config);
    addTearDown(services.dispose);
    await tester.pumpWidget(MaterialApp(home: MapScreen(services: services)));
    await tester.tap(find.text('Yakınımdakileri bul'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Müşterilerinizi konum kullanmadan'),
      findsOneWidget,
    );
  });

  testWidgets('yakında müşteri yoksa boş durum gösterir', (tester) async {
    GeolocatorPlatform.instance = _ReadyGeolocator();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      sentryDsn: '',
    );
    const sessions = _EmptySessionStore();
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode(
          request.url.path == '/api/session'
              ? {
                  'ownerId': 'user-1',
                  'workspaceId': 'workspace-1',
                  'organizationId': null,
                  'entitlement': null,
                }
              : {'data': []},
        ),
        200,
      ),
    );
    final services = MobileServices.forTesting(
      config: config,
      database: database,
      sessions: sessions,
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: sessions,
        client: client,
      ),
      sync: SyncEngine(
        database: database,
        sessions: sessions,
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: client,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: MapScreen(services: services)));
    await tester.tap(find.text('Yakınımdakileri bul'));
    await tester.pumpAndSettle();
    expect(find.text('Bu bölgede kayıtlı müşteri bulunamadı.'), findsOneWidget);
  });

  testWidgets('harita 20 müşteriyi mesafeye dizer; iç puanı göstermez', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    GeolocatorPlatform.instance = _ReadyGeolocator();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      sentryDsn: '',
    );
    final candidates = List.generate(
      20,
      (index) => {
        'id': 'customer-$index',
        'name': index == 0
            ? 'Çok Uzun İsimli Anadolu Makina Sanayi ve Ticaret Anonim Şirketi'
            : 'Müşteri $index',
        'distanceKm': index == 0 ? 0.35 : index / 10 + 0.5,
        'daysSinceVisit': null,
        'overdueTaskCount': index == 0 ? 2 : null,
        'priority': {'total': 57},
      },
    );
    final client = MockClient((request) async {
      if (request.url.path == '/api/session') {
        return http.Response(
          jsonEncode({
            'ownerId': 'user-1',
            'workspaceId': 'workspace-1',
            'organizationId': null,
            'entitlement': null,
          }),
          200,
        );
      }
      expect(request.url.queryParameters['sort'], 'distance');
      return http.Response(
        jsonEncode({'data': candidates.reversed.toList()}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    const sessions = _EmptySessionStore();
    final services = MobileServices.forTesting(
      config: config,
      database: database,
      sessions: sessions,
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: sessions,
        client: client,
      ),
      sync: SyncEngine(
        database: database,
        sessions: sessions,
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: client,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MapScreen(services: services),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yakınımdakileri bul'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('350 m'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('350 m'), findsOneWidget);
    expect(find.text('2 geciken görev'), findsOneWidget);
    expect(find.text('57'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
          (_) async =>
              http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401),
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
