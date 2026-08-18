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
import 'package:kartvizyon_mobile/features/visits/briefing_screen.dart';
import 'package:kartvizyon_mobile/features/visits/review_screen.dart';

class _EmptySessionStore extends SecureSessionStore {
  const _EmptySessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => null;
}

/// Türkçe karakter taşıyan gövde UTF-8 olarak dönmeli; `http.Response`
/// karakter kümesi verilmezse latin1 varsayar ve gövde çözülemez.
http.Response jsonResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _config = MobileConfig(
  apiBaseUrl: 'https://app.kartvizyon.app',
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon',
  sentryDsn: '',
);

MobileServices servicesWith(
  AppDatabase database,
  Future<http.Response> Function(http.Request) handler,
) => MobileServices.forTesting(
  config: _config,
  database: database,
  sessions: const _EmptySessionStore(),
  api: MobileApiClient(
    baseUrl: Uri.parse(_config.apiBaseUrl),
    sessions: const _EmptySessionStore(),
    client: MockClient(handler),
  ),
  sync: SyncEngine(
    database: database,
    sessions: const _EmptySessionStore(),
    baseUrl: Uri.parse(_config.apiBaseUrl),
    client: MockClient((_) async => http.Response('{}', 200)),
  ),
);

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  testWidgets('brifing verilen sözleri, son ziyareti ve gecikmeyi gösterir', (
    tester,
  ) async {
    final services = servicesWith(database, (request) async {
      if (request.url.path == '/api/session') {
        return jsonResponse({
          'ownerId': 'user-1',
          'workspaceId': 'workspace-1',
        });
      }
      return jsonResponse({
        'data': {
          'company': {
            'id': 'firma-1',
            'name': 'Atlas Medikal',
            'address': 'Bornova',
            'latitude': 38.46,
            'longitude': 27.21,
          },
          'memory': {
            'summary': 'Geçen ziyarette fiyat listesi istediler.',
            'open_promises': ['Numune gönderilecek'],
            'stale_after': '2020-01-01T00:00:00Z',
          },
          'openTasks': [
            {'id': 't1', 'title': 'Teklifi ilet', 'due_at': '2020-05-01'},
          ],
          'lastApprovedVisit': {'approved_at': '2026-08-11T09:00:00Z'},
        },
      });
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BriefingScreen(services: services, companyId: 'firma-1'),
      ),
    );
    await tester.pumpAndSettle();

    // Sunucu bu üçünü de döndürüyordu, ekran hiçbirini basmıyordu.
    expect(find.text('Verilen sözler (1)'), findsOneWidget);
    expect(find.text('Numune gönderilecek'), findsOneWidget);
    expect(find.textContaining('Son onaylanan ziyaret:'), findsOneWidget);
    expect(find.textContaining('gecikti'), findsOneWidget);
    expect(find.text('Güncellenmeli'), findsOneWidget);

    // Ekran çıkmaz sokaktı; artık ziyaret buradan başlatılabiliyor.
    expect(find.text('Ziyareti başlat ve not al'), findsOneWidget);
    expect(find.text('Navigasyonu aç'), findsOneWidget);
  });

  testWidgets('onay ekranı takip tarihini, kaynağı ve reddetmeyi sunar', (
    tester,
  ) async {
    final posted = <String>[];
    final services = servicesWith(database, (request) async {
      if (request.method == 'POST') {
        posted.add(request.url.path);
        return jsonResponse({'data': {}});
      }
      return jsonResponse({
        'data': {
          'id': 'visit-1',
          'status': 'needs_review',
          'company': {'id': 'firma-1', 'name': 'Atlas Medikal'},
          'transcript': 'Fiyat listesini cuma günü göndereceğimi söyledim.',
          'ai_summary': {
            'summary': 'Fiyat listesi talebi alındı ve söz verildi.',
            'outcome': 'positive',
            'followUps': [
              {
                'title': 'Fiyat listesini gönder',
                'dueDate': '2026-08-21',
                'ownerHint': 'Saha temsilcisi',
              },
            ],
          },
        },
      });
    });

    await tester.pumpWidget(
      MaterialApp(
        home: VisitReviewScreen(services: services, visitId: 'visit-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Fiyat listesini gönder'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Trigger bu tarihi göreve yazıyor; kullanıcı görmeden onaylıyordu.
    expect(find.textContaining('21.08.2026'), findsOneWidget);
    // Karşılaştıracak kaynak metin olmadan yapılan onay, onay değil kabuldür.
    await tester.scrollUntilVisible(
      find.text('Kayıt metni'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kayıt metni'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Özeti reddet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Özeti reddet'));
    await tester.pumpAndSettle();
    expect(find.text('AI özeti reddedilsin mi?'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(posted, isEmpty);

    await tester.tap(find.text('Özeti reddet'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reddet'));
    await tester.pumpAndSettle();
    expect(posted, ['/api/visits/visit-1/reject']);
  });
}
