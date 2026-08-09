import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../crdt/hlc.dart';
import '../../op/op_kind.dart';
import '../../op/operation.dart';
import '../local_store.dart';
import 'database.dart';

/// A durable, SQLite-backed [LocalStore] built on `package:drift`.
///
/// Every operation is appended to the `ops` table and never mutated in
/// place, so the op log itself is a durable audit trail. Reads that need a
/// document's current value replay the relevant rows through the CRDT
/// merge functions in `src/crdt/*` (see [SyncedDoc]) — for very long op
/// histories, pair this with periodic snapshotting at the application
/// layer (compute and cache the merged value; the op log remains the
/// source of truth for correctness).
class DriftLocalStore implements LocalStore {
  DriftLocalStore(this._db);

  /// Opens (creating if needed) a database file at [fileName] inside the
  /// platform's application-documents directory.
  static Future<DriftLocalStore> open({
    String fileName = 'sync_kit.sqlite',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));
    return DriftLocalStore(
      SyncKitDatabase(NativeDatabase.createInBackground(file)),
    );
  }

  /// An in-memory SQLite database — useful for tests or ephemeral sessions
  /// where you still want drift's query semantics without touching disk.
  factory DriftLocalStore.memory() =>
      DriftLocalStore(SyncKitDatabase(NativeDatabase.memory()));

  final SyncKitDatabase _db;
  final StreamController<OpBatch> _changes = StreamController.broadcast();

  @override
  Future<void> init() async {
    // Force the lazy connection open so callers can surface errors early.
    await _db.customSelect('SELECT 1').getSingle();
  }

  @override
  Future<void> close() async {
    await _changes.close();
    await _db.close();
  }

  @override
  Future<void> appendLocalOps(List<Operation> ops) async {
    if (ops.isEmpty) return;
    final docIds = <String>{};
    await _db.transaction(() async {
      for (final op in ops) {
        final inserted = await _insertIfNew(op);
        if (inserted) docIds.add(op.docId);
      }
    });
    if (docIds.isNotEmpty) {
      _changes.add(OpBatch(docIds: docIds, fromRemote: false));
    }
  }

  @override
  Future<List<Operation>> ingestRemoteOps(
    String adapterId,
    List<Operation> ops,
  ) async {
    final newOps = <Operation>[];
    final docIds = <String>{};
    await _db.transaction(() async {
      for (final op in ops) {
        final inserted = await _insertIfNew(op);
        if (inserted) {
          newOps.add(op);
          docIds.add(op.docId);
        }
        await _db
            .into(_db.pushStatus)
            .insertOnConflictUpdate(
              PushStatusCompanion.insert(opId: op.id, adapterId: adapterId),
            );
      }
    });
    if (docIds.isNotEmpty) {
      _changes.add(OpBatch(docIds: docIds, fromRemote: true));
    }
    return newOps;
  }

  /// Inserts [op] iff its id hasn't been seen before. Returns whether it
  /// was newly inserted.
  Future<bool> _insertIfNew(Operation op) async {
    final existing = await (_db.select(
      _db.ops,
    )..where((t) => t.id.equals(op.id))).getSingleOrNull();
    if (existing != null) return false;
    await _db.into(_db.ops).insert(_toCompanion(op));
    return true;
  }

  @override
  Future<List<Operation>> pendingOps(String adapterId, {int? limit}) async {
    final pushedIds =
        await (_db.selectOnly(_db.pushStatus)
              ..addColumns([_db.pushStatus.opId])
              ..where(_db.pushStatus.adapterId.equals(adapterId)))
            .map((row) => row.read(_db.pushStatus.opId)!)
            .get();
    final pushedSet = pushedIds.toSet();

    var query = _db.select(_db.ops)..orderBy([(t) => OrderingTerm.asc(t.seq)]);
    if (pushedSet.isNotEmpty) {
      query = query..where((t) => t.id.isNotIn(pushedSet));
    }
    if (limit != null) {
      query = query..limit(limit);
    }
    final rows = await query.get();
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> markPushed(String adapterId, Iterable<String> opIds) async {
    if (opIds.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.pushStatus, [
        for (final id in opIds)
          PushStatusCompanion.insert(opId: id, adapterId: adapterId),
      ]);
    });
  }

  @override
  Future<List<Operation>> opsForDoc(String docId) async {
    final rows =
        await (_db.select(_db.ops)
              ..where((t) => t.docId.equals(docId))
              ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
            .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<Operation>> allOps() async {
    final rows = await (_db.select(
      _db.ops,
    )..orderBy([(t) => OrderingTerm.asc(t.seq)])).get();
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Stream<OpBatch> get changes => _changes.stream;

  @override
  Future<String?> getCheckpoint(String adapterId) async {
    final row = await (_db.select(
      _db.checkpoints,
    )..where((t) => t.adapterId.equals(adapterId))).getSingleOrNull();
    return row?.checkpoint;
  }

  @override
  Future<void> setCheckpoint(String adapterId, String checkpoint) async {
    await _db
        .into(_db.checkpoints)
        .insertOnConflictUpdate(
          CheckpointsCompanion.insert(
            adapterId: adapterId,
            checkpoint: checkpoint,
          ),
        );
  }

  OpsCompanion _toCompanion(Operation op) => OpsCompanion.insert(
    id: op.id,
    docId: op.docId,
    docType: op.docType,
    field: op.field,
    kind: op.kind.wireName,
    valueJson: jsonEncode(op.value),
    hlcMillis: op.hlc.millis,
    hlcCounter: op.hlc.counter,
    hlcNodeId: op.hlc.nodeId,
    nodeId: op.nodeId,
  );

  Operation _fromRow(OpRow row) => Operation(
    id: row.id,
    docId: row.docId,
    docType: row.docType,
    field: row.field,
    kind: OpKindCodec.fromWireName(row.kind),
    value: jsonDecode(row.valueJson),
    hlc: Hlc(
      millis: row.hlcMillis,
      counter: row.hlcCounter,
      nodeId: row.hlcNodeId,
    ),
    nodeId: row.nodeId,
  );
}
