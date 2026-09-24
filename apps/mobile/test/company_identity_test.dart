import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/app.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/features/more/company_identity_screen.dart';

MobileServices services() => MobileServices.create(
  const MobileConfig(
    apiBaseUrl: 'http://localhost:3000',
    supabaseUrl: '',
    supabaseAnonKey: '',
    sentryDsn: '',
  ),
);

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  testWidgets('onboarding Ad Soyad ve firma adını kaydeder', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    Map<String, dynamic>? submitted;
    final client = MockClient((request) async {
      submitted = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        '{}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    const config = MobileConfig(
      apiBaseUrl: 'https://example.test',
      supabaseUrl: '',
      supabaseAnonKey: '',
      sentryDsn: '',
    );
    const sessions = _EmptySessionStore();
    final subject = MobileServices.forTesting(
      config: config,
      database: database,
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
    final router = GoRouter(
      initialLocation: '/company-setup',
      routes: [
        GoRoute(
          path: '/company-setup',
          builder: (_, __) =>
              CompanyIdentityScreen(services: subject, onboarding: true),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.enterText(find.byType(TextFormField).at(0), 'Burak Yılmaz');
    await tester.enterText(find.byType(TextFormField).at(1), 'Ohrili Makina');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(submitted, {
      'displayName': 'Burak Yılmaz',
      'companyName': 'Ohrili Makina',
    });
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Home gerçek adı ve firma bağlamını gösterir', (tester) async {
    final subject = services()
      ..displayName = 'Burak'
      ..workspaceCompanyName = 'Ohrili Makina';
    addTearDown(subject.dispose);
    await tester.pumpWidget(KartVizyonApp(services: subject));
    await tester.pumpAndSettle();
    expect(find.text('Merhaba Burak'), findsOneWidget);
    expect(find.text('Ohrili Makina için bugünün saha özeti'), findsOneWidget);
  });

  testWidgets(
    'boş adda Merhaba gösterir; workspace değişiminde eski ad kalmaz',
    (tester) async {
      final subject = services()..workspaceCompanyName = 'Ohrili Makina';
      addTearDown(subject.dispose);
      await tester.pumpWidget(KartVizyonApp(services: subject));
      await tester.pumpAndSettle();
      expect(find.text('Merhaba'), findsOneWidget);
      subject.workspaceCompanyName = 'Noesis Social';
      await tester.drag(find.byType(ListView).first, const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(
        find.text('Noesis Social için bugünün saha özeti'),
        findsOneWidget,
      );
      expect(find.textContaining('Ohrili Makina'), findsNothing);
    },
  );

  testWidgets('uzun Türkçe firma adı 360dp ve iki kat yazıda taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final subject = services()
      ..workspaceCompanyName =
          'Çok Uzun İsimli Anadolu Makina Sanayi ve Ticaret Anonim Şirketi';
    addTearDown(subject.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: KartVizyonApp(services: subject),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
