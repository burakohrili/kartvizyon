import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/features/visits/debrief_screen.dart';

class _SessionStore extends SecureSessionStore {
  const _SessionStore(this.token);
  final String? token;

  @override
  Future<({String accessToken, String refreshToken})?> read() async =>
      token == null ? null : (accessToken: token!, refreshToken: 'refresh');
}

const _visitId = 'visit-1';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  MobileServices servicesWith(String? token) {
    const config = MobileConfig(
      apiBaseUrl: 'https://app.kartvizyon.app',
      supabaseUrl: '',
      supabaseAnonKey: '',
      sentryDsn: '',
    );
    final sessions = _SessionStore(token);
    return MobileServices.forTesting(
      config: config,
      database: database,
      sessions: sessions,
      api: MobileApiClient(
        baseUrl: Uri.parse(config.apiBaseUrl),
        sessions: sessions,
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
      sync: SyncEngine(
        database: database,
        sessions: sessions,
        baseUrl: Uri.parse(config.apiBaseUrl),
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );
  }

  Future<GoRouter> pumpDebrief(
    WidgetTester tester,
    MobileServices services,
  ) async {
    final router = GoRouter(
      initialLocation: '/visits/$_visitId/debrief',
      routes: [
        GoRoute(
          path: '/visits',
          builder: (_, _) => const Scaffold(body: Text('Ziyaret listesi')),
        ),
        GoRoute(
          path: '/visits/:id/debrief',
          builder: (_, state) => DebriefScreen(
            services: services,
            visitId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/visits/:id/review',
          builder: (_, _) => const Scaffold(body: Text('İnceleme ekranı')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> writeNote(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextField),
      'Fiyat listesi istediler, cuma günü döneceğim.',
    );
    await tester.pumpAndSettle();
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('gönderim başarılıysa inceleme ekranına geçer', (tester) async {
    final services = servicesWith('token');
    final router = await pumpDebrief(tester, services);

    await writeNote(tester);
    await tester.tap(find.text('Güvenli kuyruğa ekle ve gönder'));
    await tester.pumpAndSettle();

    // Önce ekranda tek satırlık bir mesaj kalıyor ve kullanıcı ne olduğunu
    // anlamıyordu.
    expect(locationOf(router), '/visits/$_visitId/review');
    expect(find.text('İnceleme ekranı'), findsOneWidget);
    expect(await database.pendingForOwner(services.ownerId), isEmpty);
  });

  testWidgets('gönderilemeyen not ikinci kez kuyruğa girmez', (tester) async {
    final services = servicesWith(null);
    await pumpDebrief(tester, services);

    await writeNote(tester);
    await tester.tap(find.text('Güvenli kuyruğa ekle ve gönder'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Eşitleme merkezinden'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ziyaretlere dön'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ziyaretlere dön'), findsOneWidget);
    expect(await database.pendingForOwner(services.ownerId), hasLength(1));

    // Düğme pasifleşmeli; yeniden basmak ikinci bir kayıt üretmemeli.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Güvenli kuyruğa ekle ve gönder'),
    );
    expect(button.onPressed, isNull);
    expect(await database.pendingForOwner(services.ownerId), hasLength(1));
  });
}
