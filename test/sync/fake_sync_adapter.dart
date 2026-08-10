import 'package:flutter_crdt_sync_kit/flutter_crdt_sync_kit.dart';

/// A fake backend shared by multiple [FakeSyncAdapter]s, simulating a
/// server-side op log that many devices push to and pull from — enough to
/// test real multi-device convergence without any actual network I/O.
class FakeBackend {
  final List<Operation> _ops = [];
  final Set<String> _ids = {};
  bool failNextPush = false;
  bool failNextPull = false;

  void receive(List<Operation> ops) {
    for (final op in ops) {
      if (_ids.add(op.id)) _ops.add(op);
    }
  }

  List<Operation> since(int checkpoint) =>
      checkpoint >= _ops.length ? const [] : _ops.sublist(checkpoint);

  int get length => _ops.length;
}

class FakeSyncAdapter implements SyncAdapter {
  @override
  final String id;
  final FakeBackend backend;

  FakeSyncAdapter(this.backend, {this.id = 'fake'});

  @override
  Future<void> push(List<Operation> ops) async {
    if (backend.failNextPush) {
      backend.failNextPush = false;
      throw Exception('simulated push failure');
    }
    backend.receive(ops);
  }

  @override
  Future<PullResult> pull(String? checkpoint) async {
    if (backend.failNextPull) {
      backend.failNextPull = false;
      throw Exception('simulated pull failure');
    }
    final since = checkpoint == null ? 0 : int.parse(checkpoint);
    final ops = backend.since(since);
    return PullResult(
      ops: ops,
      nextCheckpoint: (since + ops.length).toString(),
    );
  }
}
