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
import 'package:kartvizyon_mobile/features/tasks/tasks_screen.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  testWidgets('tamamlanmış görevin tiki onaysız kaldırılmaz', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final patched = <String>[];
    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
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
        client: MockClient((request) async {
          if (request.method == 'PATCH') {
            patched.add(request.body);
            return http.Response(jsonEncode({'data': {}}), 200);
          }
          if (request.url.path == '/api/session') {
            return http.Response(
              jsonEncode({
                'ownerId': 'user-1',
                'workspaceId': 'workspace-1',
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'task-1',
                  'title': 'Fiyat listesi gönder',
                  'status': 'completed',
                  'due_at': '2026-08-20T09:00:00Z',
                },
              ],
            }),
            200,
          );
        }),
      ),
      sync: SyncEngine(
        database: database,
        sessions: const _EmptySessionStore(),
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: TasksScreen(services: services)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tamamlananlar (1)'), findsOneWidget);
    expect(find.textContaining('Son tarih 20.08.2026'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('Görev yeniden açılsın mı?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    // Onaylanmadan sunucuya hiçbir şey gitmez ve tik yerinde kalır.
    expect(patched, isEmpty);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeniden aç'));
    await tester.pumpAndSettle();

    expect(patched, hasLength(1));
    expect(patched.single, contains('"status":"open"'));
  });
}
