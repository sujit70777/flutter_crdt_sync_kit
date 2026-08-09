import 'dart:async';

import '../crdt/hlc_clock.dart';
import '../crdt/pn_counter.dart';
import '../op/op_id.dart';
import '../op/op_kind.dart';
import '../op/operation.dart';
import '../storage/local_store.dart';
import '../sync/sync_engine.dart';

/// A reactive, offline-first counter backed by a [PNCounter] CRDT.
///
/// Increments and decrements from any device, applied in any order or
/// with any redelivery, always converge to the same total — see
/// [PNCounter] for why.
///
/// ```dart
/// final likes = await SyncedCounter.open(docId: 'post_1_likes', store: store, clock: clock);
/// await likes.increment();
/// likes.stream.listen((total) => setState(() {}));
/// ```
class SyncedCounter {
  final String docId;
  final String docType;
  final LocalStore _store;
  final HlcClock _clock;
  final SyncEngine? _engine;

  final PNCounter _counter = PNCounter();
  final Set<String> _appliedOpIds = {};
  final StreamController<num> _controller = StreamController<num>.broadcast();
  StreamSubscription<OpBatch>? _sub;

  SyncedCounter._({
    required this.docId,
    required this.docType,
    required LocalStore store,
    required HlcClock clock,
    SyncEngine? engine,
  }) : _store = store,
       _clock = clock,
       _engine = engine;

  /// Opens a [SyncedCounter], replaying any operations already recorded
  /// for [docId] to reconstruct its current total.
  static Future<SyncedCounter> open({
    required String docId,
    String docType = 'counter',
    required LocalStore store,
    required HlcClock clock,
    SyncEngine? engine,
  }) async {
    final counter = SyncedCounter._(
      docId: docId,
      docType: docType,
      store: store,
      clock: clock,
      engine: engine,
    );
    await counter._refreshFromStore();
    counter._sub = store.changes.listen(counter._onStoreChange);
    return counter;
  }

  /// The current total.
  num get value => _counter.value;

  /// Emits a new total on every local or remote change.
  Stream<num> get stream => _controller.stream;

  /// Increments the counter by [delta] (default 1). [delta] must be
  /// non-negative.
  Future<void> increment([num delta = 1]) =>
      _write(OpKind.counterIncrement, delta);

  /// Decrements the counter by [delta] (default 1). [delta] must be
  /// non-negative — this reduces the total, it does not add a negative
  /// number.
  Future<void> decrement([num delta = 1]) =>
      _write(OpKind.counterDecrement, delta);

  Future<void> _write(OpKind kind, num delta) async {
    if (delta < 0) {
      throw ArgumentError.value(delta, 'delta', 'must be non-negative');
    }
    final hlc = _clock.next();
    final op = Operation(
      id: newOpId(),
      docId: docId,
      docType: docType,
      field: '',
      kind: kind,
      value: delta,
      hlc: hlc,
      nodeId: hlc.nodeId,
    );
    _appliedOpIds.add(op.id);
    _counter.apply(op);
    _controller.add(value);
    await _store.appendLocalOps([op]);
    _engine?.notifyLocalWrite();
  }

  void _onStoreChange(OpBatch batch) {
    if (!batch.docIds.contains(docId)) return;
    _refreshFromStore();
  }

  Future<void> _refreshFromStore() async {
    final ops = await _store.opsForDoc(docId);
    var changed = false;
    for (final op in ops) {
      if (op.kind != OpKind.counterIncrement &&
          op.kind != OpKind.counterDecrement) {
        continue;
      }
      if (!_appliedOpIds.add(op.id)) continue;
      final decision = _counter.apply(op);
      _clock.observe(op.hlc);
      if (decision.newValue != decision.previousValue) changed = true;
    }
    if (changed) _controller.add(value);
  }

  /// Cancels the underlying store subscription and closes [stream].
  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
