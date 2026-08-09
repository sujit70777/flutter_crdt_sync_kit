import 'package:meta/meta.dart';

/// Lifecycle events emitted by [SyncEngine.events], primarily consumed by
/// the debug [SyncKitInspector] widget and application-level logging.
@immutable
sealed class SyncEvent {
  final DateTime timestamp;
  const SyncEvent(this.timestamp);
}

class SyncCycleStarted extends SyncEvent {
  SyncCycleStarted() : super(DateTime.now());
}

class SyncPushSucceeded extends SyncEvent {
  final int opCount;
  SyncPushSucceeded(this.opCount) : super(DateTime.now());
}

class SyncPushFailed extends SyncEvent {
  final Object error;
  final int attempt;
  final Duration nextRetryDelay;
  SyncPushFailed(
    this.error, {
    required this.attempt,
    required this.nextRetryDelay,
  }) : super(DateTime.now());
}

class SyncPullSucceeded extends SyncEvent {
  final int opCount;
  SyncPullSucceeded(this.opCount) : super(DateTime.now());
}

class SyncPullFailed extends SyncEvent {
  final Object error;
  final int attempt;
  final Duration nextRetryDelay;
  SyncPullFailed(
    this.error, {
    required this.attempt,
    required this.nextRetryDelay,
  }) : super(DateTime.now());
}

class SyncCycleSkippedOffline extends SyncEvent {
  SyncCycleSkippedOffline() : super(DateTime.now());
}

class SyncCycleCompleted extends SyncEvent {
  SyncCycleCompleted() : super(DateTime.now());
}
