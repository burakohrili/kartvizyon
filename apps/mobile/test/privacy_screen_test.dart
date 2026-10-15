import 'package:drift/native.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/features/more/privacy_screen.dart';
import 'package:kartvizyon_mobile/l10n/app_localizations.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  MobileServices services({required bool configured}) {
    final config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      supabaseUrl: configured ? 'https://test.supabase.co' : '',
      supabaseAnonKey: configured ? 'test-anon-key' : '',
      sentryDsn: '',
    );
    const sessions = _EmptySessionStore();
    return MobileServices.forTesting(
      config: config,
      database: database,
      sessions: sessions,
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: sessions,
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'consents': [
                {'purpose': 'product_analytics', 'granted': true},
              ],
              'requests': [
                {
                  'id': 'export-pending',
                  'kind': 'export',
                  'status': 'requested',
                },
                {'id': 'export-ready', 'kind': 'export', 'status': 'ready'},
                {
                  'id': 'delete-pending',
                  'kind': 'deletion',
                  'status': 'processing',
                },
              ],
            }),
            200,
          );
        }),
      ),
      sync: SyncEngine(
        database: database,
        sessions: sessions,
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Locale locale, {
    required bool configured,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrivacyScreen(services: services(configured: configured)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('English privacy page and deletion confirmation are localized', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpScreen(tester, const Locale('en'), configured: false);

    expect(find.text(l10n.privacyScreenTitle), findsOneWidget);
    expect(find.text(l10n.privacyIntro), findsOneWidget);
    expect(find.text(l10n.privacySignInRequired), findsOneWidget);
    expect(find.textContaining('KVKK'), findsNothing);
    expect(find.byType(SwitchListTile), findsNWidgets(3));
    for (final tile in tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    )) {
      expect(tile.onChanged, isNull);
    }

    await tester.tap(find.text(l10n.privacyDeleteAccountPermanently));
    await tester.pumpAndSettle();
    expect(find.text(l10n.privacyDeleteConfirmTitle), findsWidgets);
    expect(find.text(l10n.privacyDeleteConfirmBody), findsOneWidget);
    expect(find.text(l10n.cancel), findsOneWidget);
  });

  testWidgets('English request list localizes API statuses and open requests', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpScreen(tester, const Locale('en'), configured: true);

    expect(find.text(l10n.privacyMyRequests), findsOneWidget);
    expect(find.text(l10n.privacyStatusReceived), findsOneWidget);
    expect(find.text(l10n.privacyStatusProcessing), findsOneWidget);
    expect(find.text(l10n.privacyStatusReady), findsOneWidget);
    expect(find.text(l10n.privacyExportRequestOpen), findsOneWidget);
    expect(find.text(l10n.privacyDeletionRequestOpen), findsOneWidget);
    expect(find.text(l10n.privacyDownload), findsOneWidget);
  });
}
