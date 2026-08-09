import 'dart:async';
import 'dart:isolate';

import '../crypto/op_encryptor.dart';
import '../op/operation.dart';
import '../storage/local_store.dart';
import 'connectivity_monitor.dart';
import 'retry_policy.dart';
import 'sync_adapter.dart';
import 'sync_event.dart';

/// Drives opportunistic, conflict-free background sync between a
/// [LocalStore] and a [SyncAdapter].
///
/// Each sync cycle:
///  1. Reads pending (not-yet-pushed) local operations and pushes them to
///     the adapter, in batches of [batchSize].
///  2. Pulls operations recorded on the backend since the last checkpoint.
///  3. Deduplicates and persists newly-seen operations into [LocalStore]
///     (which fans them out to any live [SyncedDoc]/[SyncedCounter]/
///     [SyncedSet], each applying its own CRDT merge — deterministically,
///     regardless of the order operations were received in).
///
/// Cycles run on a [pollInterval] timer, immediately after a local write
/// ([notifyLocalWrite]), whenever [connectivity] regains connectivity, and
/// whenever the adapter signals new data via [RealtimeSyncAdapter]. On
/// failure, retries follow [retryPolicy]'s exponential backoff rather than
/// hammering the backend.
class SyncEngine {
  final LocalStore store;
  final SyncAdapter adapter;
  final Duration pollInterval;
  final int batchSize;
  final ConnectivityMonitor connectivity;
  final OpEncryptor encryptor;
  final RetryPolicy retryPolicy;
  final Duration writeDebounce;

  /// When a pulled batch has at least this many operations, its
  /// CPU-bound validation/ordering pass runs on a background isolate via
  /// [Isolate.run] instead of the calling isolate, so a large initial
  /// sync doesn't jank the UI. The network I/O itself is always
  /// non-blocking `async`/`await` regardless of this setting.
  final int isolateBatchThreshold;

  final StreamController<SyncEvent> _events = StreamController.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<void>? _realtimeSub;
  Timer? _pollTimer;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _running = false;
  bool _syncing = false;
  bool _rerunRequested = false;
  int _failureStreak = 0;

  SyncEngine({
    required this.store,
    required this.adapter,
    this.pollInterval = const Duration(seconds: 30),
    this.batchSize = 200,
    ConnectivityMonitor? connectivity,
    OpEncryptor? encryptor,
    RetryPolicy? retryPolicy,
    this.writeDebounce = const Duration(milliseconds: 300),
    this.isolateBatchThreshold = 500,
  }) : connectivity = connectivity ?? const AlwaysOnlineMonitor(),
       encryptor = encryptor ?? const NoopOpEncryptor(),
       retryPolicy = retryPolicy ?? RetryPolicy();

  /// Sync lifecycle events, primarily for [SyncKitInspector] and logging.
  Stream<SyncEvent> get events => _events.stream;

  /// Starts the periodic poll timer and connectivity/realtime listeners,
  /// and immediately attempts a sync cycle.
  void start() {
    if (_running) return;
    _running = true;
    _pollTimer = Timer.periodic(pollInterval, (_) => syncNow());
    _connectivitySub = connectivity.onlineStream.listen((online) {
      if (online) syncNow();
    });
    if (adapter case RealtimeSyncAdapter realtimeAdapter) {
      _realtimeSub = realtimeAdapter.remoteChangeSignal.listen(
        (_) => syncNow(),
      );
    }
    unawaited(syncNow());
  }

  /// Cancels all timers/subscriptions. Does not close [store].
  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _retryTimer?.cancel();
    _debounceTimer?.cancel();
    await _connectivitySub?.cancel();
    await _realtimeSub?.cancel();
  }

  /// Call after a local write so pending operations reach the backend
  /// promptly rather than waiting for the next poll. Debounced by
  /// [writeDebounce] so a burst of edits triggers one sync, not many.
  void notifyLocalWrite() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(writeDebounce, syncNow);
  }

  /// Runs one sync cycle immediately (push then pull). Safe to call while
  /// a cycle is already in progress — the request is coalesced into a
  /// single rerun once the current cycle finishes.
  Future<void> syncNow() async {
    if (_syncing) {
      _rerunRequested = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _rerunRequested = false;
        await _runCycle();
      } while (_rerunRequested);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _runCycle() async {
    _events.add(SyncCycleStarted());

    if (!await connectivity.isOnline) {
      _events.add(SyncCycleSkippedOffline());
      return;
    }

    final pushOk = await _push();
    final pullOk = pushOk ? await _pull() : false;

    if (pushOk && pullOk) {
      _failureStreak = 0;
      _retryTimer?.cancel();
    } else {
      _scheduleRetry();
    }
    _events.add(SyncCycleCompleted());
  }

  Future<bool> _push() async {
    try {
      final pending = await store.pendingOps(adapter.id, limit: batchSize);
      if (pending.isEmpty) return true;
      final ordered = await _prepareBatch(pending);
      final encrypted = await Future.wait(ordered.map(encryptor.encrypt));
      await adapter.push(encrypted);
      await store.markPushed(adapter.id, ordered.map((op) => op.id));
      _events.add(SyncPushSucceeded(ordered.length));
      return true;
    } catch (error) {
      _failureStreak++;
      final delay = retryPolicy.delayFor(_failureStreak);
      _events.add(
        SyncPushFailed(error, attempt: _failureStreak, nextRetryDelay: delay),
      );
      return false;
    }
  }

  Future<bool> _pull() async {
    try {
      final checkpoint = await store.getCheckpoint(adapter.id);
      final result = await adapter.pull(checkpoint);
      if (result.ops.isNotEmpty) {
        final ordered = await _prepareBatch(result.ops);
        final decrypted = await Future.wait(ordered.map(encryptor.decrypt));
        final newOps = await store.ingestRemoteOps(adapter.id, decrypted);
        _events.add(SyncPullSucceeded(newOps.length));
      } else {
        _events.add(SyncPullSucceeded(0));
      }
      if (result.nextCheckpoint != null) {
        await store.setCheckpoint(adapter.id, result.nextCheckpoint!);
      }
      return true;
    } catch (error) {
      _failureStreak++;
      final delay = retryPolicy.delayFor(_failureStreak);
      _events.add(
        SyncPullFailed(error, attempt: _failureStreak, nextRetryDelay: delay),
      );
      return false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delay = retryPolicy.delayFor(_failureStreak);
    _retryTimer = Timer(delay, syncNow);
  }

  Future<List<Operation>> _prepareBatch(List<Operation> ops) {
    if (ops.length < isolateBatchThreshold) {
      return Future.value(_sortedByHlc(ops));
    }
    return Isolate.run(() => _sortedByHlc(ops));
  }
}

List<Operation> _sortedByHlc(List<Operation> ops) {
  final copy = List<Operation>.of(ops);
  copy.sort((a, b) => a.hlc.compareTo(b.hlc));
  return copy;
}
