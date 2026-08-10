import 'dart:async';

import 'package:flutter_crdt_sync_kit/flutter_crdt_sync_kit.dart';

/// A stand-in "server" for this demo: a single shared, in-memory op log
/// that every [DemoSyncAdapter] pushes to and pulls from, so the app can
/// show real multi-device convergence without needing a live backend.
///
/// In a real app you would use [SupabaseSyncAdapter] or [RestSyncAdapter]
/// (both included in sync_kit) instead — this class exists purely so the
/// example runs standalone.
class DemoBackend {
  final List<Operation> _ops = [];
  final Set<String> _ids = {};
  final StreamController<void> _changeSignal = StreamController.broadcast();

  void receive(List<Operation> ops) {
    var added = false;
    for (final op in ops) {
      if (_ids.add(op.id)) {
        _ops.add(op);
        added = true;
      }
    }
    if (added) _changeSignal.add(null);
  }

  List<Operation> since(int checkpoint) =>
      checkpoint >= _ops.length ? const [] : _ops.sublist(checkpoint);

  Stream<void> get onChange => _changeSignal.stream;
}

/// Talks to a [DemoBackend] exactly the way [SupabaseSyncAdapter] or
/// [RestSyncAdapter] would talk to a real one — this class is the whole
/// contract a custom [SyncAdapter] needs to implement.
class DemoSyncAdapter implements SyncAdapter, RealtimeSyncAdapter {
  @override
  final String id;
  final DemoBackend backend;

  DemoSyncAdapter(this.backend, {required this.id});

  @override
  Future<void> push(List<Operation> ops) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 150),
    ); // simulate network latency
    backend.receive(ops);
  }

  @override
  Future<PullResult> pull(String? checkpoint) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final since = checkpoint == null ? 0 : int.parse(checkpoint);
    final ops = backend.since(since);
    return PullResult(
      ops: ops,
      nextCheckpoint: (since + ops.length).toString(),
    );
  }

  @override
  Stream<void> get remoteChangeSignal => backend.onChange;
}
