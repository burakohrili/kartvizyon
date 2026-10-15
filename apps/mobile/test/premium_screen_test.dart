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
import 'package:kartvizyon_mobile/features/more/premium_screen.dart';
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

  MobileServices servicesFor({required bool configured}) {
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
          final response = {
            'workspaceKind': 'organization',
            'usage': <String, dynamic>{},
            'entitlement': {
              'readOnly': true,
              'trialActive': false,
              'trialEndsAt': null,
              'limits': {
                'companies': null,
                'ocr': null,
                'aiMinutes': null,
                'aiSummaries': null,
                'seats': 1,
              },
            },
          };
          return http.Response(jsonEncode(response), 200);
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
    WidgetTester tester, {
    required Locale locale,
    required bool configured,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PremiumScreen(services: servicesFor(configured: configured)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('organization plan screen uses English catalog copy', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpScreen(tester, locale: const Locale('en'), configured: true);

    expect(find.text(l10n.premiumTitle), findsOneWidget);
    expect(find.text(l10n.organizationPlanName), findsOneWidget);
    expect(find.text(l10n.organizationPlanManaged), findsOneWidget);
    expect(find.textContaining('Premium ve abonelik'), findsNothing);
    expect(find.textContaining('TRY'), findsNothing);
  });

  testWidgets('unconfigured account error follows Turkish locale', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    await pumpScreen(tester, locale: const Locale('tr'), configured: false);

    expect(find.text(l10n.premiumTitle), findsOneWidget);
    expect(find.text(l10n.billingSessionRequired), findsOneWidget);
  });
}
