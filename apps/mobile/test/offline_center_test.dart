import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';
import 'package:kartvizyon_mobile/data/sync_error_labels.dart';
import 'package:kartvizyon_mobile/features/offline/offline_center_screen.dart';
import 'package:kartvizyon_mobile/l10n/app_localizations.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  group('hata etiketleri', () {
    test('Türkçe ve İngilizce hata açıklaması sunar', () async {
      final tr = await AppLocalizations.delegate.load(const Locale('tr'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));

      expect(syncErrorLabel(null, tr), tr.syncErrorWaiting);
      expect(syncErrorLabel('http_413', tr), contains('25 MB'));
      expect(syncErrorLabel('http_402', tr), contains('kota'));
      expect(syncErrorLabel('network_error', tr), contains('Bağlantı'));
      expect(syncErrorLabel('http_503', tr), contains('Sunucu'));
      expect(syncErrorLabel(null, en), en.syncErrorWaiting);
      expect(syncErrorLabel('http_413', en), contains('25 MB'));
      expect(syncErrorLabel('http_402', en), contains('quota'));
      expect(syncErrorLabel('network_error', en), contains('connect'));
      expect(syncErrorLabel('http_503', en), contains('server'));
    });

    test('kalıcı hata öneki etiketi değiştirmez', () async {
      final tr = await AppLocalizations.delegate.load(const Locale('tr'));
      expect(
        syncErrorLabel('${syncBlockedPrefix}http_415', tr),
        syncErrorLabel('http_415', tr),
      );
    });

    test('bilinmeyen kod da yine bir çıkış yolu sunar', () async {
      final tr = await AppLocalizations.delegate.load(const Locale('tr'));
      expect(syncErrorLabel('http_418', tr), contains('silebilirsiniz'));
    });
  });

  group('eşitleme merkezi', () {
    late AppDatabase database;
    late MobileServices services;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      const config = MobileConfig(
        apiBaseUrl: 'https://app.kartvizyon.app',
        supabaseUrl: '',
        supabaseAnonKey: '',
        sentryDsn: '',
      );
      services = MobileServices.forTesting(
        config: config,
        database: database,
        sessions: const _EmptySessionStore(),
        api: MobileApiClient(
          baseUrl: Uri.parse(config.apiBaseUrl),
          sessions: const _EmptySessionStore(),
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
        sync: SyncEngine(
          database: database,
          sessions: const _EmptySessionStore(),
          baseUrl: Uri.parse(config.apiBaseUrl),
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );
      await database.enqueue(
        SyncQueueItemsCompanion.insert(
          id: 'row-1',
          ownerId: services.ownerId,
          workspaceId: 'workspace-1',
          entityType: 'visit_debrief',
          clientMutationId: 'mutation-1',
          payloadJson: '{"visitId":"visit-1"}',
          createdAt: DateTime.utc(2026, 8, 18),
        ),
      );
      await database.markFailure('mutation-1', '${syncBlockedPrefix}http_413');
    });

    tearDown(() => database.close());

    Future<void> pump(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OfflineCenterScreen(services: services),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Türkçe arayüz hata kodu yerine açıklama gösterir', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await pump(tester, const Locale('tr'));

      expect(find.text(syncErrorLabel('http_413', l10n)), findsOneWidget);
      // Ham kod yalnız hata bildirimi satırında kalır, ana açıklama değildir.
      expect(find.text('${syncBlockedPrefix}http_413'), findsNothing);
      expect(find.textContaining('gönderilemiyor'), findsOneWidget);
    });

    testWidgets('English UI localizes offline center controls and errors', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pump(tester, const Locale('en'));

      expect(find.text(l10n.offlineCenterTitle), findsOneWidget);
      expect(find.text(l10n.syncNow), findsOneWidget);
      expect(
        find.textContaining('${l10n.syncEntityVisitNote} ·'),
        findsOneWidget,
      );
      expect(find.text(l10n.syncErrorAudioTooLarge), findsOneWidget);
      expect(find.textContaining('could not be sent'), findsOneWidget);
      expect(find.textContaining('encrypted'), findsNothing);
    });

    testWidgets('kaydı silme onay ister ve kuyruğu boşaltır', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await pump(tester, const Locale('tr'));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.delete).last);
      await tester.pumpAndSettle();

      // Onaylanmadan hiçbir şey silinmez.
      expect(await database.pendingForOwner(services.ownerId), hasLength(1));

      await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
      await tester.pumpAndSettle();

      expect(await database.pendingForOwner(services.ownerId), isEmpty);
    });
  });
}
