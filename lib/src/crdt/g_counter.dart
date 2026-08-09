import '../op/op_kind.dart';
import '../op/operation.dart';
import 'lww_register.dart';

/// A Grow-only Counter: a CRDT that only ever increases.
///
/// Rather than tracking one cumulative total per replica (the classical
/// G-Counter representation), sync_kit stores each increment's delta keyed
/// by its unique [Operation.id]. This makes [apply] idempotent under
/// at-least-once delivery without requiring the caller to deduplicate
/// operations first: applying the same increment twice contributes its
/// delta only once, and increments observed in any order sum to the same
/// total. That commutativity, associativity and idempotency (CmRDT
/// properties) are exactly what let two offline replicas apply each
/// other's increments in any order and converge.
class GCounter {
  final Map<String, num> _contributions = {};

  /// The current total: the sum of every distinct increment applied so far.
  num get value => _contributions.values.fold<num>(0, (a, b) => a + b);

  /// Applies an increment operation. [op.value] must be a non-negative
  /// [num] delta.
  ///
  /// Accepts [OpKind.counterIncrement] directly, or [OpKind.counterDecrement]
  /// when this [GCounter] is being used as [PNCounter]'s internal
  /// decrements accumulator (a PN-Counter is just two grow-only counters).
  MergeDecision apply(Operation op) {
    assert(
      op.kind == OpKind.counterIncrement || op.kind == OpKind.counterDecrement,
      'GCounter.apply requires a counter delta operation, got ${op.kind}',
    );
    final delta = op.value as num;
    assert(delta >= 0, 'GCounter increments must be non-negative, got $delta');
    final previous = value;
    if (_contributions.containsKey(op.id)) {
      return MergeDecision(
        operation: op,
        outcome: ApplyOutcome.ignored,
        previousValue: previous,
        newValue: previous,
      );
    }
    _contributions[op.id] = delta;
    return MergeDecision(
      operation: op,
      outcome: ApplyOutcome.applied,
      previousValue: previous,
      newValue: value,
    );
  }
}
