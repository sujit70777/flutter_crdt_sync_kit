import 'package:drift/drift.dart';

/// The op log: every CRDT operation ever recorded on this device, local or
/// remote. `seq` preserves insertion order for debug tooling; merge
/// correctness never depends on it (CRDT operations are commutative).
@DataClassName('OpRow')
class Ops extends Table {
  /// Auto-incrementing insertion order; not part of the CRDT identity of a
  /// row, just a convenient replay/debug ordering.
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get id => text().unique()();
  TextColumn get docId => text()();
  TextColumn get docType => text()();
  TextColumn get field => text()();
  TextColumn get kind => text()();
  TextColumn get valueJson => text()();
  IntColumn get hlcMillis => integer()();
  IntColumn get hlcCounter => integer()();
  TextColumn get hlcNodeId => text()();
  TextColumn get nodeId => text()();
}

/// Tracks which operations have already been pushed to which sync adapter,
/// so `pendingOps` never re-sends an operation and remote-origin operations
/// are never echoed straight back to their source.
@DataClassName('PushStatusRow')
class PushStatus extends Table {
  TextColumn get opId => text()();
  TextColumn get adapterId => text()();

  @override
  Set<Column> get primaryKey => {opId, adapterId};
}

/// The last sync cursor/checkpoint successfully pulled from each adapter.
@DataClassName('CheckpointRow')
class Checkpoints extends Table {
  TextColumn get adapterId => text()();
  TextColumn get checkpoint => text()();

  @override
  Set<Column> get primaryKey => {adapterId};
}
