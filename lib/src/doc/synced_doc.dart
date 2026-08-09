import 'dart:async';

import 'package:collection/collection.dart';

import '../crdt/hlc.dart';
import '../crdt/hlc_clock.dart';
import '../crdt/lww_register.dart';
import '../op/op_id.dart';
import '../op/op_kind.dart';
import '../op/operation.dart';
import '../storage/local_store.dart';
import '../sync/sync_engine.dart';
import 'document_codec.dart';

/// A reactive, offline-first document backed by field-level LWW-Register
/// CRDTs.
///
/// ```dart
/// final doc = await SyncedDoc.open<TodoItem>(
///   docId: 'todo_123',
///   docType: 'todo',
///   store: store,
///   clock: clock,
///   codec: todoCodec,
///   empty: TodoItem.empty(),
/// );
/// doc.update((t) => t.copyWith(done: true)); // works offline instantly
/// doc.stream.listen((t) => setState(() {})); // reflects local + remote merges
/// ```
///
/// Every [update] diffs the returned value against the current one and
/// writes only the fields that actually changed, each as its own
/// [Operation]. That per-field granularity is what lets two devices edit
/// different fields of the same document while offline and have both
/// edits survive the merge.
class SyncedDoc<T> {
  final String docId;
  final String docType;
  final LocalStore _store;
  final HlcClock _clock;
  final DocumentCodec<T> _codec;
  final SyncEngine? _engine;

  final Map<String, LwwRegister<Object?>> _fields = {};
  final Set<String> _appliedOpIds = {};
  final StreamController<T> _controller = StreamController<T>.broadcast();
  StreamSubscription<OpBatch>? _sub;
  T _value;

  SyncedDoc._({
    required this.docId,
    required this.docType,
    required LocalStore store,
    required HlcClock clock,
    required DocumentCodec<T> codec,
    required T initialValue,
    SyncEngine? engine,
  }) : _store = store,
       _clock = clock,
       _codec = codec,
       _engine = engine,
       _value = initialValue;

  /// Opens a [SyncedDoc], replaying any operations already recorded for
  /// [docId] in [store] to reconstruct its current value.
  ///
  /// [empty] provides default field values for any field never written
  /// (e.g. a brand-new document, or a field added to `T` after older
  /// operations were recorded).
  static Future<SyncedDoc<T>> open<T>({
    required String docId,
    required String docType,
    required LocalStore store,
    required HlcClock clock,
    required DocumentCodec<T> codec,
    required T empty,
    SyncEngine? engine,
  }) async {
    final doc = SyncedDoc<T>._(
      docId: docId,
      docType: docType,
      store: store,
      clock: clock,
      codec: codec,
      initialValue: empty,
      engine: engine,
    );
    await doc._loadInitial();
    doc._sub = store.changes.listen(doc._onStoreChange);
    return doc;
  }

  /// The current merged value.
  T get value => _value;

  /// Emits a new value every time [update] is called locally, or whenever
  /// a remote operation changes this document.
  Stream<T> get stream => _controller.stream;

  Future<void> _loadInitial() async {
    final ops = await _store.opsForDoc(docId);
    _applyOps(ops);
  }

  void _onStoreChange(OpBatch batch) {
    if (!batch.docIds.contains(docId)) return;
    _refreshFromStore();
  }

  Future<void> _refreshFromStore() async {
    final ops = await _store.opsForDoc(docId);
    final changed = _applyOps(ops);
    if (changed) _controller.add(_value);
  }

  bool _applyOps(List<Operation> ops) {
    var changed = false;
    for (final op in ops) {
      if (op.kind != OpKind.lwwSet) continue;
      if (!_appliedOpIds.add(op.id)) continue;
      final register = _fields.putIfAbsent(
        op.field,
        () => LwwRegister<Object?>(
          _defaultFields()[op.field],
          Hlc.zero(op.hlc.nodeId),
        ),
      );
      final decision = register.apply(op);
      if (decision.outcome == ApplyOutcome.applied) changed = true;
      _clock.observe(op.hlc);
    }
    if (changed) {
      _rebuildValue();
    }
    return changed;
  }

  Map<String, Object?> _defaultFields() => _codec.toFields(_value);

  void _rebuildValue() {
    final defaults = _codec.toFields(_value);
    final fields = <String, Object?>{
      for (final key in defaults.keys)
        key: _fields[key]?.value ?? defaults[key],
    };
    _value = _codec.fromFields(fields);
  }

  /// Computes `mutator(value)`, diffs it against the current value, and
  /// writes an [Operation] for each field that changed. Safe to call while
  /// fully offline — writes are applied locally and persisted immediately;
  /// syncing to a backend happens opportunistically via the configured
  /// [SyncEngine], whenever connectivity allows.
  Future<void> update(T Function(T current) mutator) async {
    final next = mutator(_value);
    final before = _codec.toFields(_value);
    final after = _codec.toFields(next);

    const equality = DeepCollectionEquality();
    final ops = <Operation>[];
    for (final key in after.keys) {
      if (before.containsKey(key) && equality.equals(before[key], after[key])) {
        continue;
      }
      final hlc = _clock.next();
      final op = Operation(
        id: newOpId(),
        docId: docId,
        docType: docType,
        field: key,
        kind: OpKind.lwwSet,
        value: after[key],
        hlc: hlc,
        nodeId: hlc.nodeId,
      );
      ops.add(op);
      _appliedOpIds.add(op.id);
      _fields
          .putIfAbsent(
            key,
            () => LwwRegister<Object?>(before[key], Hlc.zero(hlc.nodeId)),
          )
          .apply(op);
    }

    if (ops.isEmpty) return;
    _rebuildValue();
    _controller.add(_value);
    await _store.appendLocalOps(ops);
    _engine?.notifyLocalWrite();
  }

  /// Cancels the underlying store subscription and closes [stream]. Does
  /// not close [_store] or [_engine], which may be shared by other
  /// documents.
  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
