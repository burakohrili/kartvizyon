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

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

void main() {
  group('hata etiketleri', () {
    test('ham kod yerine sebebi ve çıkış yolunu söyler', () {
      expect(syncErrorLabel(null), 'Gönderilmeyi bekliyor');
      expect(syncErrorLabel('http_413'), contains('25 MB'));
      expect(syncErrorLabel('http_402'), contains('kota'));
      expect(syncErrorLabel('network_error'), contains('Bağlantı'));
      expect(syncErrorLabel('http_503'), contains('Sunucu'));
    });

    test('kalıcı hata öneki etiketi değiştirmez', () {
      expect(
        syncErrorLabel('${syncBlockedPrefix}http_415'),
        syncErrorLabel('http_415'),
      );
    });

    test('bilinmeyen kod da yine bir çıkış yolu sunar', () {
      expect(syncErrorLabel('http_418'), contains('silebilirsiniz'));
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
      await database.markFailure(
        'mutation-1',
        '${syncBlockedPrefix}http_413',
      );
    });

    tearDown(() => database.close());

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: OfflineCenterScreen(services: services)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('ham hata kodu yerine Türkçe açıklama gösterir', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text(syncErrorLabel('http_413')), findsOneWidget);
      // Ham kod yalnız hata bildirimi satırında kalır, ana açıklama değildir.
      expect(find.text('${syncBlockedPrefix}http_413'), findsNothing);
      expect(find.textContaining('gönderilemiyor'), findsOneWidget);
    });

    testWidgets('kaydı silme onay ister ve kuyruğu boşaltır', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydı sil'));
      await tester.pumpAndSettle();

      // Onaylanmadan hiçbir şey silinmez.
      expect(await database.pendingForOwner(services.ownerId), hasLength(1));

      await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
      await tester.pumpAndSettle();

      expect(await database.pendingForOwner(services.ownerId), isEmpty);
    });
  });
}
