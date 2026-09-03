import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class SyncQueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get workspaceId => text()();
  TextColumn get entityType => text()();
  TextColumn get clientMutationId => text().unique()();
  TextColumn get payloadJson => text()();
  TextColumn get attachmentPath => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [SyncQueueItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<SyncQueueItem>> pendingForOwner(String ownerId) =>
      (select(syncQueueItems)
            ..where((row) => row.ownerId.equals(ownerId))
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<void> enqueue(SyncQueueItemsCompanion item) =>
      into(syncQueueItems).insert(item, mode: InsertMode.insertOrReplace);
  Future<int> removeByMutationId(String mutationId) => (delete(
    syncQueueItems,
  )..where((row) => row.clientMutationId.equals(mutationId))).go();

  /// Kalıcı hata işaretini kaldırır ki kayıt yeniden denenebilsin.
  ///
  /// Deneme sayacı da sıfırlanır; kullanıcı "tekrar dene" dediğinde ekranda
  /// eski denemelerin sayısını görmesi kafa karıştırıyor.
  Future<int> clearFailure(String mutationId) =>
      (update(
        syncQueueItems,
      )..where((row) => row.clientMutationId.equals(mutationId))).write(
        const SyncQueueItemsCompanion(
          lastError: Value(null),
          attempts: Value(0),
        ),
      );

  Future<int> markFailure(String mutationId, String error) async {
    final current =
        await (select(syncQueueItems)
              ..where((row) => row.clientMutationId.equals(mutationId)))
            .getSingleOrNull();
    if (current == null) return 0;
    return (update(
      syncQueueItems,
    )..where((row) => row.clientMutationId.equals(mutationId))).write(
      SyncQueueItemsCompanion(
        attempts: Value(current.attempts + 1),
        lastError: Value(error),
      ),
    );
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  return NativeDatabase.createInBackground(
    File(p.join(directory.path, 'kartvizyon.sqlite')),
  );
});
