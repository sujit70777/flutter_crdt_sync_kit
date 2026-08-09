import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// The generated drift database backing [DriftLocalStore]. Not part of
/// sync_kit's public API — use [DriftLocalStore] instead.
@DriftDatabase(tables: [Ops, PushStatus, Checkpoints])
class SyncKitDatabase extends _$SyncKitDatabase {
  SyncKitDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
