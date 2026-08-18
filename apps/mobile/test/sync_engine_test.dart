import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';
import 'package:kartvizyon_mobile/data/secure_session_store.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';

class _FakeSessionStore extends SecureSessionStore {
  const _FakeSessionStore();

  @override
  Future<({String accessToken, String refreshToken})?> read() async => (
    accessToken: 'token',
    refreshToken: 'refresh',
  );
}

void main() {
  test('başarılı istek kuyruktan silinmeye uygundur', () {
    expect(classifySyncStatus(200), SyncDisposition.success);
    expect(classifySyncStatus(201), SyncDisposition.success);
  });

  test('oturum, kayıt ve sunucu hatalarını ayırır', () {
    expect(classifySyncStatus(401), SyncDisposition.authRequired);
    // 409 yalnız o kaydı ilgilendirir; kuyruğun kalanı denenmeye devam eder.
    expect(classifySyncStatus(409), SyncDisposition.retryItem);
    // 429 ve 5xx sunucu genelinde; turu bitir.
    expect(classifySyncStatus(429), SyncDisposition.retryRun);
    expect(classifySyncStatus(503), SyncDisposition.retryRun);
    expect(classifySyncStatus(422), SyncDisposition.permanentFailure);
    expect(classifySyncStatus(413), SyncDisposition.permanentFailure);
  });

  group('kuyruk tek bir kayıt yüzünden durmaz', () {
    late AppDatabase database;
    setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => database.close());

    Future<void> enqueue(String mutation, DateTime createdAt) =>
        database.enqueue(
          SyncQueueItemsCompanion.insert(
            id: mutation,
            ownerId: 'user-a',
            workspaceId: 'workspace-1',
            entityType: 'visit_debrief',
            clientMutationId: mutation,
            payloadJson: '{"visitId":"visit-$mutation","transcript":"not"}',
            createdAt: createdAt,
          ),
        );

    SyncEngine engineReturning(List<int> statuses, List<Uri> seen) {
      var index = 0;
      return SyncEngine(
        database: database,
        sessions: const _FakeSessionStore(),
        baseUrl: Uri.parse('https://app.kartvizyon.app'),
        client: MockClient((request) async {
          seen.add(request.url);
          final status = statuses[index.clamp(0, statuses.length - 1)];
          index += 1;
          return http.Response('{}', status);
        }),
      );
    }

    test('kalıcı hata alan kayıt sıradakini engellemez', () async {
      await enqueue('first', DateTime.utc(2026, 8, 18, 9));
      await enqueue('second', DateTime.utc(2026, 8, 18, 10));

      final seen = <Uri>[];
      final result = await engineReturning([413, 200], seen).run(
        ownerId: 'user-a',
      );

      // Eski davranış: 413 sonrası döngü kırılıyor ve ikinci kayıt hiç
      // denenmiyordu.
      expect(seen, hasLength(2));
      expect(result.synced, 1);
      expect(result.blocked, 1);

      final pending = await database.pendingForOwner('user-a');
      expect(pending, hasLength(1));
      expect(pending.single.clientMutationId, 'first');
      expect(isSyncBlocked(pending.single.lastError), isTrue);
    });

    test('kalıcı hataya düşen kayıt bir daha gönderilmez', () async {
      await enqueue('first', DateTime.utc(2026, 8, 18, 9));

      final seen = <Uri>[];
      final engine = engineReturning([415], seen);
      await engine.run(ownerId: 'user-a');
      await engine.run(ownerId: 'user-a');

      expect(seen, hasLength(1));
      final pending = await database.pendingForOwner('user-a');
      // Kayıt silinmez; kullanıcı eşitleme merkezinden karar verir.
      expect(pending, hasLength(1));
      expect(pending.single.attempts, 1);
    });

    test('409 alan kayıt kuyruğu kilitlemez ve kalıcı sayılmaz', () async {
      await enqueue('first', DateTime.utc(2026, 8, 18, 9));
      await enqueue('second', DateTime.utc(2026, 8, 18, 10));

      final seen = <Uri>[];
      final result = await engineReturning([409, 200], seen).run(
        ownerId: 'user-a',
      );

      expect(seen, hasLength(2));
      expect(result.synced, 1);
      expect(result.blocked, 0);
      final pending = await database.pendingForOwner('user-a');
      expect(isSyncBlocked(pending.single.lastError), isFalse);
    });

    test('sunucu hatası turu bitirir', () async {
      await enqueue('first', DateTime.utc(2026, 8, 18, 9));
      await enqueue('second', DateTime.utc(2026, 8, 18, 10));

      final seen = <Uri>[];
      await engineReturning([503, 200], seen).run(ownerId: 'user-a');

      // 5xx'te sunucuyu dövmemek için sıradaki kayda geçilmez.
      expect(seen, hasLength(1));
    });
  });

  test('sesli not sunucunun kabul ettiği bir türle gönderilir', () {
    // MultipartFile.fromPath tür verilmezse parçayı application/octet-stream
    // olarak gönderir; sunucu bunu 415 ile reddeder ve sesli not kuyrukta
    // kalır. Sunucunun kabul ettiği liste
    // apps/web/src/lib/openai/visit-ai.ts içindeki acceptedAudioTypes'tır.
    const accepted = {
      'audio/webm',
      'audio/mp4',
      'audio/mpeg',
      'audio/wav',
      'audio/x-m4a',
    };
    final source = File('lib/data/sync_engine.dart').readAsStringSync();
    final start = source.indexOf('MultipartFile.fromPath(');
    expect(start, greaterThan(-1), reason: 'sesli not yüklemesi bulunamadı');
    final call = source.substring(start, source.indexOf(');', start));
    expect(
      call.contains('contentType:'),
      isTrue,
      reason: 'ses parçası tür beyan etmeden gönderilemez',
    );
    final media = RegExp("MediaType[(]'([^']+)', *'([^']+)'[)]").firstMatch(
      call,
    );
    expect(media, isNotNull, reason: 'beyan edilen tür okunamadı');
    expect(accepted, contains('${media!.group(1)}/${media.group(2)}'));
  });
}
