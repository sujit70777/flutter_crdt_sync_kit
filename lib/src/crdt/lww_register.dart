import 'package:meta/meta.dart';

import '../op/op_kind.dart';
import '../op/operation.dart';
import 'hlc.dart';

/// Outcome of applying an [Operation] to a CRDT register/counter/set.
enum ApplyOutcome {
  /// The operation changed the CRDT's value.
  applied,

  /// The operation was valid but lost to a concurrent/later write (LWW), or
  /// added no new information (idempotent replay). The CRDT is unchanged.
  ignored,
}

/// Result of applying an operation, primarily useful for the debug
/// [SyncKitInspector] widget to explain merge decisions.
@immutable
class MergeDecision {
  final Operation operation;
  final ApplyOutcome outcome;
  final Object? previousValue;
  final Object? newValue;

  const MergeDecision({
    required this.operation,
    required this.outcome,
    required this.previousValue,
    required this.newValue,
  });
}

/// A Last-Write-Wins register: the CRDT behind an ordinary "edit a field"
/// use case.
///
/// Every write is stamped with an [Hlc]. When two writes are concurrent
/// (neither happened causally after the other), the write with the greater
/// [Hlc] wins deterministically on every node, so all replicas converge to
/// the same value regardless of delivery order. This is what makes
/// [LwwRegister.apply] safe to call with operations arriving in any order,
/// any number of times (applying the same operation again is a no-op).
class LwwRegister<T> {
  T _value;
  Hlc _hlc;

  LwwRegister(T initial, Hlc initialHlc) : _value = initial, _hlc = initialHlc;

  /// The current value: whichever write has the greatest [Hlc] observed so
  /// far.
  T get value => _value;

  /// The [Hlc] of the write currently "winning".
  Hlc get hlc => _hlc;

  /// Applies [op], which must have `kind == OpKind.lwwSet`.
  ///
  /// The op wins and replaces [value] iff its [Hlc] is strictly greater
  /// than the current one. Ties are impossible in practice (an [Hlc]'s
  /// nodeId makes it unique per node), but are resolved in favor of the
  /// existing value to keep [apply] idempotent for exact replays.
  MergeDecision apply(Operation op) {
    assert(
      op.kind == OpKind.lwwSet,
      'LwwRegister.apply requires OpKind.lwwSet, got ${op.kind}',
    );
    final previous = _value;
    if (op.hlc > _hlc) {
      _value = op.value as T;
      _hlc = op.hlc;
      return MergeDecision(
        operation: op,
        outcome: ApplyOutcome.applied,
        previousValue: previous,
        newValue: _value,
      );
    }
    return MergeDecision(
      operation: op,
      outcome: ApplyOutcome.ignored,
      previousValue: previous,
      newValue: previous,
    );
  }
}
