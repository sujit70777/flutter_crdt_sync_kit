import '../op/op_kind.dart';
import '../op/operation.dart';
import 'g_counter.dart';
import 'lww_register.dart';

/// A Positive-Negative Counter: like [GCounter] but supports decrements too.
///
/// Internally this is two [GCounter]s (increments and decrements); the
/// value is their difference. Because each underlying counter is itself an
/// idempotent, commutative CmRDT, `increments - decrements` converges
/// regardless of the order operations are applied in.
class PNCounter {
  final GCounter _increments = GCounter();
  final GCounter _decrements = GCounter();

  /// The current total: `sum(increments) - sum(decrements)`.
  num get value => _increments.value - _decrements.value;

  /// Applies an [OpKind.counterIncrement] or [OpKind.counterDecrement]
  /// operation. [op.value] must be a non-negative [num] delta.
  MergeDecision apply(Operation op) {
    final previous = value;
    final MergeDecision inner;
    switch (op.kind) {
      case OpKind.counterIncrement:
        inner = _increments.apply(op);
      case OpKind.counterDecrement:
        inner = _decrements.apply(op);
      default:
        throw ArgumentError(
          'PNCounter.apply requires counterIncrement or counterDecrement, got ${op.kind}',
        );
    }
    return MergeDecision(
      operation: op,
      outcome: inner.outcome,
      previousValue: previous,
      newValue: value,
    );
  }
}
