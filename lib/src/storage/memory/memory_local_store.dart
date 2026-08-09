import 'dart:async';

import '../../op/operation.dart';
import '../local_store.dart';

/// A pure-Dart, in-memory [LocalStore].
///
/// Nothing is written to disk — state is lost when the process exits. This
/// is the right choice for unit tests, server-side/CLI usage, or as a
/// drop-in default before wiring up [DriftLocalStore] for real persistence.
class InMemoryLocalStore implements LocalStore {
  final List<Operation> _ops = [];
  final Set<String> _knownOpIds = {};
  final Map<String, Set<String>> _pushedTo = {}; // opId -> adapterIds
  final Map<String, String> _checkpoints = {}; // adapterId -> checkpoint
  final StreamController<OpBatch> _changes = StreamController.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {
    await _changes.close();
  }

  @override
  Future<void> appendLocalOps(List<Operation> ops) async {
    if (ops.isEmpty) return;
    final docIds = <String>{};
    for (final op in ops) {
      if (_knownOpIds.add(op.id)) {
        _ops.add(op);
        docIds.add(op.docId);
      }
    }
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
    for (final op in ops) {
      if (_knownOpIds.add(op.id)) {
        _ops.add(op);
        newOps.add(op);
        docIds.add(op.docId);
      }
      (_pushedTo[op.id] ??= {}).add(adapterId);
    }
    if (docIds.isNotEmpty) {
      _changes.add(OpBatch(docIds: docIds, fromRemote: true));
    }
    return newOps;
  }

  @override
  Future<List<Operation>> pendingOps(String adapterId, {int? limit}) async {
    final pending = _ops.where(
      (op) => !(_pushedTo[op.id]?.contains(adapterId) ?? false),
    );
    return (limit == null ? pending : pending.take(limit)).toList(
      growable: false,
    );
  }

  @override
  Future<void> markPushed(String adapterId, Iterable<String> opIds) async {
    for (final id in opIds) {
      (_pushedTo[id] ??= {}).add(adapterId);
    }
  }

  @override
  Future<List<Operation>> opsForDoc(String docId) async =>
      _ops.where((op) => op.docId == docId).toList(growable: false);

  @override
  Future<List<Operation>> allOps() async => List.unmodifiable(_ops);

  @override
  Stream<OpBatch> get changes => _changes.stream;

  @override
  Future<String?> getCheckpoint(String adapterId) async =>
      _checkpoints[adapterId];

  @override
  Future<void> setCheckpoint(String adapterId, String checkpoint) async {
    _checkpoints[adapterId] = checkpoint;
  }
}
