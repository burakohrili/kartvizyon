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
import 'package:kartvizyon_mobile/features/more/workspace_module_screen.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  testWidgets('boş modül ekranı ne olduğunu anlatır ve yenileme sunar', (
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
    final services = MobileServices.forTesting(
      config: config,
      database: database,
      sessions: const _EmptySessionStore(),
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: const _EmptySessionStore(),
        client: MockClient(
          (_) async => http.Response(jsonEncode({'data': []}), 200),
        ),
      ),
      sync: SyncEngine(
        database: database,
        sessions: const _EmptySessionStore(),
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceModuleScreen(
          services: services,
          module: WorkspaceModule.opportunities,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Eskiden burada yalnız "Fırsatlar için henüz kayıt bulunmuyor." yazıyordu.
    expect(find.text('Fırsat kaydı yok'), findsOneWidget);
    expect(find.textContaining('web çalışma alanında'), findsOneWidget);
    expect(find.text('Yenile'), findsOneWidget);
  });
}
