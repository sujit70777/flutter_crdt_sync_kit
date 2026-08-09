import 'dart:async';

import '../crdt/hlc_clock.dart';
import '../crdt/lww_register.dart' show ApplyOutcome;
import '../crdt/or_set.dart';
import '../op/op_id.dart';
import '../op/op_kind.dart';
import '../op/operation.dart';
import '../storage/local_store.dart';
import '../sync/sync_engine.dart';

/// A reactive, offline-first collection backed by an [ORSet] CRDT.
///
/// Adds and removes from any device merge without the lost-update bugs of
/// a naive last-write-wins set — see [ORSet] for the add-wins semantics.
///
/// ```dart
/// final tags = await SyncedSet<String>.open(docId: 'post_1_tags', store: store, clock: clock);
/// await tags.add('flutter');
/// tags.stream.listen((elements) => setState(() {}));
/// ```
class SyncedSet<E> {
  final String docId;
  final String docType;
  final LocalStore _store;
  final HlcClock _clock;
  final SyncEngine? _engine;

  final ORSet<E> _set = ORSet<E>();
  final Set<String> _appliedOpIds = {};
  final StreamController<Set<E>> _controller =
      StreamController<Set<E>>.broadcast();
  StreamSubscription<OpBatch>? _sub;

  SyncedSet._({
    required this.docId,
    required this.docType,
    required LocalStore store,
    required HlcClock clock,
    SyncEngine? engine,
  }) : _store = store,
       _clock = clock,
       _engine = engine;

  /// Opens a [SyncedSet], replaying any operations already recorded for
  /// [docId] to reconstruct its current contents.
  static Future<SyncedSet<E>> open<E>({
    required String docId,
    String docType = 'set',
    required LocalStore store,
    required HlcClock clock,
    SyncEngine? engine,
  }) async {
    final set = SyncedSet<E>._(
      docId: docId,
      docType: docType,
      store: store,
      clock: clock,
      engine: engine,
    );
    await set._refreshFromStore();
    set._sub = store.changes.listen(set._onStoreChange);
    return set;
  }

  /// The current set contents.
  Set<E> get elements => _set.elements;

  /// Emits the current contents on every local or remote change.
  Stream<Set<E>> get stream => _controller.stream;

  /// Adds [element]. Concurrent adds of the same element from different
  /// devices are harmless — the set converges to containing it once.
  Future<void> add(E element) async {
    final hlc = _clock.next();
    final op = Operation(
      id: newOpId(),
      docId: docId,
      docType: docType,
      field: '',
      kind: OpKind.setAdd,
      value: element,
      hlc: hlc,
      nodeId: hlc.nodeId,
    );
    _appliedOpIds.add(op.id);
    _set.apply(op);
    _controller.add(elements);
    await _store.appendLocalOps([op]);
    _engine?.notifyLocalWrite();
  }

  /// Removes [element], if present. Only observed-remove tags known to
  /// this device at call time are removed, per the OR-Set algorithm — a
  /// concurrent add from another device that this device hasn't seen yet
  /// will survive.
  Future<void> remove(E element) async {
    final tags = _set.tagsFor(element);
    if (tags.isEmpty) return;
    final hlc = _clock.next();
    final op = Operation(
      id: newOpId(),
      docId: docId,
      docType: docType,
      field: '',
      kind: OpKind.setRemove,
      value: tags,
      hlc: hlc,
      nodeId: hlc.nodeId,
    );
    _appliedOpIds.add(op.id);
    _set.apply(op);
    _controller.add(elements);
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
      if (op.kind != OpKind.setAdd && op.kind != OpKind.setRemove) continue;
      if (!_appliedOpIds.add(op.id)) continue;
      final decision = _set.apply(op);
      _clock.observe(op.hlc);
      if (decision.outcome == ApplyOutcome.applied) changed = true;
    }
    if (changed) _controller.add(elements);
  }

  /// Cancels the underlying store subscription and closes [stream].
  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
