import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'local/app_database.dart';

class SyncQueueRepository {
  SyncQueueRepository(this.database);
  final AppDatabase database;
  static const _uuid = Uuid();

  Future<String> enqueueVisitCreate({
    required String ownerId,
    required String workspaceId,
    required String? organizationId,
    required String companyId,
    required String purpose,
  }) async {
    final mutationId = _uuid.v4();
    await database.enqueue(
      SyncQueueItemsCompanion.insert(
        id: _uuid.v4(),
        ownerId: ownerId,
        workspaceId: workspaceId,
        entityType: 'visit_create',
        clientMutationId: mutationId,
        payloadJson: jsonEncode({
          'workspaceId': workspaceId,
          'organizationId': organizationId,
          'companyId': companyId,
          'purpose': purpose,
          'startedAt': DateTime.now().toUtc().toIso8601String(),
          'clientMutationId': mutationId,
        }),
        createdAt: DateTime.now().toUtc(),
      ),
    );
    return mutationId;
  }

  Future<String> enqueueVisitDebrief({
    required String ownerId,
    required String workspaceId,
    required String visitId,
    required String transcript,
    String? audioPath,
  }) async {
    final mutationId = _uuid.v4();
    await database.enqueue(
      SyncQueueItemsCompanion.insert(
        id: _uuid.v4(),
        ownerId: ownerId,
        workspaceId: workspaceId,
        entityType: 'visit_debrief',
        clientMutationId: mutationId,
        payloadJson: jsonEncode({'visitId': visitId, 'transcript': transcript}),
        attachmentPath: Value(audioPath),
        createdAt: DateTime.now().toUtc(),
      ),
    );
    return mutationId;
  }
}
