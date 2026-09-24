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

MobileServices _services(
  AppDatabase database,
  Future<http.Response> Function(http.Request) handler,
) {
  const config = MobileConfig(
    apiBaseUrl: 'https://app.kartvizyon.app',
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
    sentryDsn: '',
  );
  return MobileServices.forTesting(
    config: config,
    database: database,
    sessions: const _EmptySessionStore(),
    api: MobileApiClient(
      baseUrl: Uri.parse(config.apiBaseUrl),
      sessions: const _EmptySessionStore(),
      client: MockClient(handler),
    ),
    sync: SyncEngine(
      database: database,
      sessions: const _EmptySessionStore(),
      baseUrl: Uri.parse(config.apiBaseUrl),
      client: MockClient((_) async => http.Response('{}', 200)),
    ),
  );
}

void main() {
  testWidgets('boş bildirim merkezi ne tür olayların geleceğini anlatır', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceModuleScreen(
          services: _services(
            database,
            (_) async => http.Response(jsonEncode({'data': []}), 200),
          ),
          module: WorkspaceModule.notifications,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Şimdilik yeni bildiriminiz yok.'), findsOneWidget);
    expect(find.textContaining('Yaklaşan ziyaretler'), findsOneWidget);
    expect(find.byTooltip('Bildirim tercihleri'), findsOneWidget);
  });

  testWidgets('bildirim tercihleri üç güvenli anahtarı gösterir', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final services = _services(database, (request) async {
      if (request.url.path == '/api/settings/notifications') {
        return http.Response(
          jsonEncode({
            'data': {
              'visitReminders': true,
              'taskReminders': true,
              'fieldModeMorning': true,
            },
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceModuleScreen(
          services: services,
          module: WorkspaceModule.notifications,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bildirim tercihleri'));
    await tester.pumpAndSettle();
    expect(find.text('Ziyaret hatırlatmaları'), findsOneWidget);
    expect(find.text('Görev hatırlatmaları'), findsOneWidget);
    expect(find.text('Sabah saha hatırlatması'), findsOneWidget);
  });

  testWidgets('izin reddi 360dp ve yüzde 200 yazıda taşmadan açıklanır', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final services = _services(database, (request) async {
      if (request.url.path == '/api/settings/notifications') {
        return http.Response(
          jsonEncode({
            'data': {
              'visitReminders': true,
              'taskReminders': true,
              'fieldModeMorning': true,
            },
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });
    services.reminders.permissionDenied.value = true;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: WorkspaceModuleScreen(
          services: services,
          module: WorkspaceModule.notifications,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bildirim tercihleri'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sistem bildirimleri kapalı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
