import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/features/field_mode/field_mode_service.dart';
import 'package:kartvizyon_mobile/l10n/app_localizations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();
  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

class _FieldGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  _FieldGeolocator({this.permission = LocationPermission.whileInUse});
  final LocationPermission permission;
  final positions = StreamController<Position>.broadcast();
  Position get position => Position(
    latitude: 38.46,
    longitude: 27.21,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => position;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      positions.stream;
}

MobileServices _services(
  http.Client client, {
  Future<String?> Function()? accessTokenProvider,
  Future<String?> Function()? refreshAccessToken,
  DateTime Function()? fieldModeNow,
}) {
  const config = MobileConfig(
    apiBaseUrl: 'https://app.kartvizyon.app',
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
    sentryDsn: '',
  );
  const sessions = _EmptySessionStore();
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  late MobileServices services;
  services = MobileServices.forTesting(
    config: config,
    database: database,
    sessions: sessions,
    api: MobileApiClient(
      baseUrl: Uri.parse(config.apiBaseUrl),
      sessions: sessions,
      accessTokenProvider: accessTokenProvider,
      refreshAccessToken: refreshAccessToken,
      workspaceId: () => services.workspaceId,
      onSessionExpired: () => services.sessionExpired.value = true,
      client: client,
    ),
    sync: SyncEngine(
      database: database,
      sessions: sessions,
      baseUrl: Uri.parse(config.apiBaseUrl),
      client: client,
    ),
    fieldModeNotificationPermissionCheck: () async => true,
    fieldModeNow: fieldModeNow ?? () => DateTime(2026, 9, 23, 10),
  );

  return services;
}

http.Response _session({
  bool readOnly = false,
  String workspace = 'workspace-a',
}) => http.Response(
  jsonEncode({
    'ownerId': 'user-1',
    'workspaceId': workspace,
    'organizationId': null,
    'entitlement': {
      'readOnly': readOnly,
      'accessEndsAt': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    },
  }),
  200,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('yakın müşteri bildirimi seçili dile göre biçimlenir', () async {
    final services = _services(MockClient((_) async => _session()));
    addTearDown(services.dispose);
    final candidate = <String, dynamic>{
      'distanceKm': 1.25,
      'daysSinceVisit': 3,
      'overdueTaskCount': 2,
    };

    final turkish = await AppLocalizations.delegate.load(const Locale('tr'));
    services.fieldMode.setLocale('tr');
    expect(
      services.fieldMode.describeCandidate(candidate, turkish),
      '1,3 km uzakta · Son ziyaret 3 gün önce · 2 geciken takip',
    );

    final english = await AppLocalizations.delegate.load(const Locale('en'));
    services.fieldMode.setLocale('en');
    expect(
      services.fieldMode.describeCandidate(candidate, english),
      '1.3 km away · Last visited 3 days ago · 2 overdue follow-ups',
    );
  });

  test('geçerli oturum bile 21.00 saatinde saha modunu başlatamaz', () async {
    final services = _services(
      MockClient((_) async => _session()),
      fieldModeNow: () => DateTime(2026, 9, 23, 21),
    );
    addTearDown(services.dispose);
    expect(await services.fieldMode.start(), isFalse);
    expect(services.fieldMode.isActive.value, isFalse);
    expect(services.sessionExpired.value, isFalse);
    expect(services.fieldMode.lastMessage.value, FieldModeMessage.afterHours);
  });

  test(
    'geçerli oturumda saha modu açılır; login yönlendirmesi yoktur',
    () async {
      final geo = _FieldGeolocator();
      GeolocatorPlatform.instance = geo;
      final services = _services(MockClient((_) async => _session()));
      addTearDown(() async {
        await services.dispose();
        await geo.positions.close();
      });
      expect(
        await services.fieldMode.start(),
        isTrue,
        reason: services.fieldMode.lastMessage.value?.name,
      );
      expect(services.fieldMode.isActive.value, isTrue);
      expect(services.sessionExpired.value, isFalse);
    },
  );

  test(
    'saha modu açılır açılmaz mevcut konumu yakındaki müşteriler için sorar',
    () async {
      final geo = _FieldGeolocator();
      GeolocatorPlatform.instance = geo;
      var candidateChecks = 0;
      final services = _services(
        MockClient((request) async {
          if (request.url.path == '/api/session') return _session();
          if (request.url.path == '/api/geofence/candidates') {
            candidateChecks++;
            return http.Response(jsonEncode({'data': <Object>[]}), 200);
          }
          return http.Response(jsonEncode({'data': <Object>[]}), 200);
        }),
      );
      addTearDown(() async {
        await services.dispose();
        await geo.positions.close();
      });

      expect(await services.fieldMode.start(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(candidateChecks, 1);

      await services.fieldMode.onAppResumed();
      expect(candidateChecks, 2);
    },
  );

  test('eski access token yenilenir; saha modu login olmadan açılır', () async {
    final geo = _FieldGeolocator();
    GeolocatorPlatform.instance = geo;
    var refreshed = 0;
    final services = _services(
      MockClient((request) async {
        if (request.headers['authorization'] == 'Bearer expired') {
          return http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401);
        }
        return _session();
      }),
      accessTokenProvider: () async => 'expired',
      refreshAccessToken: () async {
        refreshed++;
        return 'fresh';
      },
    );
    addTearDown(() async {
      await services.dispose();
      await geo.positions.close();
    });
    expect(await services.fieldMode.start(), isTrue);
    expect(refreshed, 1);
    expect(services.sessionExpired.value, isFalse);
  });

  test(
    'geçersiz refresh doğrulanınca saha modu durur ve login sinyali verir',
    () async {
      final geo = _FieldGeolocator();
      GeolocatorPlatform.instance = geo;
      final services = _services(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'error': 'Oturum gerekli.'}), 401),
        ),
        accessTokenProvider: () async => 'expired',
        refreshAccessToken: () async => null,
      );
      addTearDown(() async {
        await services.dispose();
        await geo.positions.close();
      });
      expect(await services.fieldMode.start(), isFalse);
      expect(services.fieldMode.isActive.value, isFalse);
      expect(services.sessionExpired.value, isTrue);
    },
  );

  test('sunucu 500 saha modunu yarı aktif bırakmaz, login açmaz', () async {
    final geo = _FieldGeolocator();
    GeolocatorPlatform.instance = geo;
    final services = _services(MockClient((_) async => http.Response('', 500)));
    addTearDown(() async {
      await services.dispose();
      await geo.positions.close();
    });
    expect(await services.fieldMode.start(), isFalse);
    expect(services.fieldMode.isActive.value, isFalse);
    expect(services.sessionExpired.value, isFalse);
    expect(services.fieldMode.lastMessage.value, FieldModeMessage.startFailed);
  });

  test('konum izni reddi login değil açık hata gösterir', () async {
    final geo = _FieldGeolocator(permission: LocationPermission.deniedForever);
    GeolocatorPlatform.instance = geo;
    final services = _services(MockClient((_) async => _session()));
    addTearDown(() async {
      await services.dispose();
      await geo.positions.close();
    });
    expect(await services.fieldMode.start(), isFalse);
    expect(services.sessionExpired.value, isFalse);
    expect(
      services.fieldMode.lastMessage.value,
      FieldModeMessage.locationPermission,
    );
  });

  test('read-only saha modunu engeller ama login açmaz', () async {
    final geo = _FieldGeolocator();
    GeolocatorPlatform.instance = geo;
    final services = _services(
      MockClient((_) async => _session(readOnly: true)),
    );
    addTearDown(() async {
      await services.dispose();
      await geo.positions.close();
    });
    expect(await services.fieldMode.start(), isFalse);
    expect(services.sessionExpired.value, isFalse);
    expect(
      services.fieldMode.lastMessage.value,
      FieldModeMessage.accessRequired,
    );
  });

  test(
    'workspace değişiminden sonra adaylar yeni workspace ile istenir',
    () async {
      final geo = _FieldGeolocator();
      GeolocatorPlatform.instance = geo;
      String? candidateWorkspace;
      final services = _services(
        MockClient((request) async {
          if (request.url.path == '/api/session') {
            return _session(
              workspace:
                  request.headers['x-kartvizyon-workspace'] ?? 'workspace-a',
            );
          }
          if (request.url.path == '/api/geofence/candidates') {
            candidateWorkspace = request.url.queryParameters['workspaceId'];
          }
          return http.Response(jsonEncode({'data': []}), 200);
        }),
      );
      addTearDown(() async {
        await services.dispose();
        await geo.positions.close();
      });
      await services.switchWorkspace('workspace-b');
      expect(
        await services.fieldMode.start(),
        isTrue,
        reason: services.fieldMode.lastMessage.value?.name,
      );
      geo.positions.add(
        Position(
          latitude: 38.46,
          longitude: 27.21,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(candidateWorkspace, 'workspace-b');
    },
  );
}
