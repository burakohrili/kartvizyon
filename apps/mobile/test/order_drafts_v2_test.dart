import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/features/more/order_draft_form_screen.dart';
import 'package:kartvizyon_mobile/features/more/workspace_module_screen.dart';

class _Session extends SecureSessionStore {
  const _Session();
  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

http.Response _response(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

MobileServices _services(
  AppDatabase database,
  Future<http.Response> Function(http.Request) handler,
) => MobileServices.forTesting(
  config: const MobileConfig(
    apiBaseUrl: 'https://app.kartvizyon.app',
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
    sentryDsn: '',
  ),
  database: database,
  sessions: const _Session(),
  api: MobileApiClient(
    baseUrl: Uri.parse('https://app.kartvizyon.app'),
    sessions: const _Session(),
    client: MockClient(handler),
  ),
  sync: SyncEngine(
    database: database,
    sessions: const _Session(),
    baseUrl: Uri.parse('https://app.kartvizyon.app'),
    client: MockClient((_) async => _response({})),
  ),
);

Map<String, dynamic> _session() => {
  'ownerId': '00000000-0000-4000-8000-000000000001',
  'workspaceId': '00000000-0000-4000-8000-000000000002',
  'workspaceKind': 'organization',
  'displayName': 'Ayşe Satış',
  'entitlement': {
    'readOnly': false,
    'accessEndsAt': DateTime.now()
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String(),
  },
};

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  testWidgets('reddedilmiş sipariş nedenini ve düzenleme aksiyonunu gösterir', (
    tester,
  ) async {
    final service = _services(database, (request) async {
      if (request.url.path == '/api/session') return _response(_session());
      return _response({
        'data': [
          {
            'id': 'order-1',
            'status': 'rejected',
            'currency': 'TRY',
            'grand_total': 1250,
            'created_at': '2026-09-20T10:00:00Z',
            'rejected_reason': 'Fiyat güncellenmeli',
            'rejected_at': '2026-09-20T11:00:00Z',
            'decision_actor_name': 'Ayşe Satış',
            'company': {'id': 'company-1', 'name': 'ABC Market'},
            'items': [],
          },
        ],
        'canApprove': true,
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceModuleScreen(
          services: service,
          module: WorkspaceModule.orders,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reddedildi'));
    await tester.pump();
    expect(find.text('ABC Market'), findsOneWidget);
    await tester.tap(find.text('ABC Market'));
    await tester.pumpAndSettle();
    expect(find.text('Neden: Fiyat güncellenmeli'), findsOneWidget);
    expect(find.text('Reddeden: Ayşe Satış'), findsOneWidget);
    expect(find.text('Düzenle ve taslağa al'), findsOneWidget);
    await service.dispose();
  });

  testWidgets('sipariş formu 360dp ve yüzde 200 yazıda açılır', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _services(database, (request) async {
      if (request.url.path == '/api/session') return _response(_session());
      return _response({'data': []});
    });
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: OrderDraftFormScreen(services: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yeni sipariş taslağı'), findsOneWidget);
    expect(find.text('Müşteri seç *'), findsOneWidget);
    expect(find.text('Ürün ekle'), findsOneWidget);
    await service.dispose();
  });
}
