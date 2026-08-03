import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/data/local/app_database.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  SyncQueueItemsCompanion item(String id, String owner, String mutation) =>
      SyncQueueItemsCompanion.insert(
        id: id,
        ownerId: owner,
        workspaceId: 'workspace-1',
        entityType: 'visit_debrief',
        clientMutationId: mutation,
        payloadJson: '{"visitId":"visit-1"}',
        createdAt: DateTime.utc(2026, 8, 3),
      );

  test('offline kuyruk kayıtlarını kullanıcıya göre izole eder', () async {
    await database.enqueue(item('1', 'user-a', 'mutation-1'));
    await database.enqueue(item('2', 'user-b', 'mutation-2'));
    final userA = await database.pendingForOwner('user-a');
    expect(userA, hasLength(1));
    expect(userA.single.ownerId, 'user-a');
  });

  test('aynı client mutation için tek kuyruk kaydı tutar', () async {
    await database.enqueue(item('first', 'user-a', 'stable-mutation'));
    await database.enqueue(item('second', 'user-a', 'stable-mutation'));
    expect(await database.pendingForOwner('user-a'), hasLength(1));
  });
}
