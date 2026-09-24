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
import 'package:kartvizyon_mobile/features/customers/customer_detail_screen.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  testWidgets('müşteri kartı düzenleme, kişi ve güvenli arşivleme sunar', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      sentryDsn: '',
    );
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'company': {
            'name': 'ABC Makina',
            'display_name': 'ABC',
            'address': 'İzmir',
            'phone': '555 000 00 00',
            'email': 'satis@abc.example',
            'website': 'https://abc.example',
          },
          'memory': null,
          'contacts': [
            {
              'id': '00000000-0000-4000-8000-000000000201',
              'first_name': 'Ayşe',
              'last_name': 'Yılmaz',
              'title': 'Satın Alma',
            },
          ],
          'tasks': const [],
          'dependencies': {
            'contacts': 1,
            'visits': 14,
            'openTasks': 4,
            'opportunities': 2,
            'orders': 1,
            'documents': 2,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final services = MobileServices.forTesting(
      config: config,
      database: database,
      sessions: const _EmptySessionStore(),
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: const _EmptySessionStore(),
        client: client,
      ),
      sync: SyncEngine(
        database: database,
        sessions: const _EmptySessionStore(),
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: client,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          services: services,
          companyId: '00000000-0000-4000-8000-000000000101',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Müşteriyi düzenle'), findsOneWidget);
    expect(find.text('Kişi ekle'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ayşe Yılmaz'), 200);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);

    await tester.ensureVisible(find.text('Müşteriyi arşivle'));
    await tester.tap(find.text('Müşteriyi arşivle'));
    await tester.pumpAndSettle();
    expect(find.text('ABC Makina arşivlensin mi?'), findsOneWidget);
    expect(find.textContaining('14 ziyaret'), findsOneWidget);
    expect(find.textContaining('Bu kayıtlar silinmeyecek'), findsOneWidget);
  });
}
