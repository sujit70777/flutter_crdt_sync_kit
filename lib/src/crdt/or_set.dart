import '../op/op_kind.dart';
import '../op/operation.dart';
import 'lww_register.dart';

/// An Observed-Remove Set ("OR-Set"): add/remove a collection's elements
/// without the lost-update bugs of a naive last-write-wins set.
///
/// Every add is tagged with the [Operation.id] that created it. A remove
/// does not simply delete the element — it records the specific tags it
/// *observed* at the time of removal. An add whose tag was never observed
/// by a given remove survives it. This "add-wins" semantics is what CRDT
/// literature calls an OR-Set, and it is what lets one offline replica add
/// an element while another concurrently removes a different (or even the
/// same) element without either update silently disappearing: concurrent
/// add and remove of the *same* element results in the element staying
/// present, because the add's tag could not have been observed by the
/// remove that raced it.
class ORSet<E> {
  final Map<String, E> _tags = {};
  final Set<String> _removedTags = {};

  /// The current set contents: every added element whose tag has not been
  /// observed-removed.
  Set<E> get elements => {
    for (final entry in _tags.entries)
      if (!_removedTags.contains(entry.key)) entry.value,
  };

  /// Tags (operation ids) currently making [element] a member of the set.
  /// A [SyncedSet.remove] call uses this to build the `setRemove`
  /// operation's payload — the removal must reference the exact tags it
  /// observed, not just the element's identity.
  List<String> tagsFor(E element) => [
    for (final entry in _tags.entries)
      if (entry.value == element && !_removedTags.contains(entry.key))
        entry.key,
  ];

  /// Applies an [OpKind.setAdd] or [OpKind.setRemove] operation.
  ///
  /// - `setAdd`: registers `op.value` as a live element under tag `op.id`.
  /// - `setRemove`: `op.value` must be a `List` of tags; every listed tag
  ///   is marked removed. Tags not yet seen (a remove arriving before its
  ///   corresponding add, e.g. out of causal order) are simply recorded and
  ///   will suppress the add once it does arrive.
  ///
  /// Both operations are naturally idempotent (map assignment / set union),
  /// so replays and out-of-order delivery are always safe.
  MergeDecision apply(Operation op) {
    final previous = elements;
    switch (op.kind) {
      case OpKind.setAdd:
        _tags[op.id] = op.value as E;
      case OpKind.setRemove:
        final tags = (op.value as List).cast<String>();
        _removedTags.addAll(tags);
      default:
        throw ArgumentError(
          'ORSet.apply requires setAdd or setRemove, got ${op.kind}',
        );
    }
    final next = elements;
    final changed = !_setEquals(previous, next);
    return MergeDecision(
      operation: op,
      outcome: changed ? ApplyOutcome.applied : ApplyOutcome.ignored,
      previousValue: previous,
      newValue: next,
    );
  }

  bool _setEquals(Set<E> a, Set<E> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
