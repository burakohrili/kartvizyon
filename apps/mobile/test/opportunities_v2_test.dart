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
import 'package:kartvizyon_mobile/features/more/opportunity_form_screen.dart';
import 'package:kartvizyon_mobile/features/more/workspace_module_screen.dart';

class _Session extends SecureSessionStore {
  const _Session();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

http.Response response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

MobileServices services(
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
    client: MockClient((_) async => response({})),
  ),
);

Map<String, dynamic> session() => {
  'ownerId': '00000000-0000-4000-8000-000000000001',
  'workspaceId': '00000000-0000-4000-8000-000000000002',
  'workspaceKind': 'personal',
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

  testWidgets('edit formu tüm opportunity alanlarını doldurur', (tester) async {
    final service = services(database, (request) async {
      if (request.url.path == '/api/session') return response(session());
      return response({
        'data': [],
        'owners': [
          {
            'user_id': '00000000-0000-4000-8000-000000000001',
            'profile': {'full_name': 'Ayşe Satış'},
          },
        ],
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        home: OpportunityFormScreen(
          services: service,
          opportunity: {
            'id': '00000000-0000-4000-8000-000000000010',
            'title': 'Yeni Soğutma Sistemi',
            'company': {
              'id': '00000000-0000-4000-8000-000000000011',
              'name': 'Çok Uzun ABC Market Sanayi ve Ticaret AŞ',
              'address': 'Bornova / İzmir',
            },
            'estimated_value': 250000,
            'currency': 'USD',
            'stage': 'proposal',
            'probability': 50,
            'expected_close_date': '2026-10-15',
            'competitor': 'Rakip A',
            'assigned_to': '00000000-0000-4000-8000-000000000001',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yeni Soğutma Sistemi'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('Teklif'), findsOneWidget);
    expect(find.text('%50'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('opportunity-close-date')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.textContaining('15.10.2026'), findsOneWidget);
    await service.dispose();
  });

  testWidgets('liste currency toplamlarını ayırır ve won/lost filtreler', (
    tester,
  ) async {
    final service = services(database, (request) async {
      if (request.url.path == '/api/session') return response(session());
      return response({
        'owners': [],
        'data': [
          {
            'id': '1',
            'title': 'TRY fırsat',
            'stage': 'proposal',
            'estimated_value': 1000,
            'currency': 'TRY',
            'probability': 50,
            'company': {'name': 'ABC'},
          },
          {
            'id': '2',
            'title': 'USD fırsat',
            'stage': 'qualified',
            'estimated_value': 2000,
            'currency': 'USD',
            'probability': 25,
            'company': {'name': 'XYZ'},
          },
          {
            'id': '3',
            'title': 'Kazanılan fırsat',
            'stage': 'won',
            'estimated_value': 3000,
            'currency': 'EUR',
            'probability': 100,
            'company': {'name': 'DEF'},
          },
        ],
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceModuleScreen(
          services: service,
          module: WorkspaceModule.opportunities,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TRY 1000'), findsOneWidget);
    expect(find.text('USD 2000'), findsOneWidget);
    expect(find.textContaining('EUR 3000'), findsNothing);
    expect(find.text('Kazanılan fırsat'), findsNothing);
    await tester.tap(find.text('Kazanılan'));
    await tester.pump();
    expect(find.text('Kazanılan fırsat'), findsOneWidget);
    await service.dispose();
  });

  testWidgets('create formu 360dp ve yüzde 200 yazıda taşmaz', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = services(database, (request) async {
      if (request.url.path == '/api/session') return response(session());
      return response({'data': [], 'owners': []});
    });
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: OpportunityFormScreen(services: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yeni fırsat'), findsOneWidget);
    expect(find.text('TRY'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('opportunity-probability')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('%10'), findsOneWidget);
    await service.dispose();
  });
}
