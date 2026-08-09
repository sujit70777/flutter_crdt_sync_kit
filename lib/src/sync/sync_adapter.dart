import '../op/operation.dart';

/// The result of a [SyncAdapter.pull] call.
class PullResult {
  /// Operations the backend has recorded since the last checkpoint, from
  /// any device.
  final List<Operation> ops;

  /// The new checkpoint/cursor to persist and pass to the next [SyncAdapter.pull]
  /// call. `null` means "unchanged" (leave the previous checkpoint as-is).
  final String? nextCheckpoint;

  const PullResult({required this.ops, this.nextCheckpoint});
}

/// Backend-agnostic transport for sync_kit's op log.
///
/// A [SyncAdapter] does not know anything about CRDT merge semantics — its
/// only job is moving [Operation]s to and from a backend. sync_kit ships
/// [SupabaseSyncAdapter] and [RestSyncAdapter]; implement this interface
/// directly to support any other backend (Firebase, PocketBase, a custom
/// server, ...).
abstract class SyncAdapter {
  /// A short, stable identifier for this adapter (e.g. `'supabase'`).
  /// Used as the key for push/pull-checkpoint bookkeeping in [LocalStore],
  /// so keep it constant across app versions once chosen.
  String get id;

  /// Sends [ops] to the backend. Must either durably record every
  /// operation in [ops] or throw — partial success should be reported by
  /// throwing after best-effort delivery, since [SyncEngine] will retry
  /// the whole batch (delivery is idempotent thanks to [Operation.id]).
  Future<void> push(List<Operation> ops);

  /// Fetches operations recorded on the backend since [checkpoint] (`null`
  /// on the very first sync). Implementations should return operations
  /// from *all* devices, including this one's own past pushes — sync_kit
  /// deduplicates by [Operation.id] locally, so redelivery is harmless.
  Future<PullResult> pull(String? checkpoint);
}

/// Optional capability for adapters that can proactively signal "there is
/// probably new data" (e.g. a Supabase realtime channel or a websocket),
/// instead of relying solely on [SyncEngine]'s poll interval.
abstract class RealtimeSyncAdapter {
  /// Emits an event whenever the backend signals a change. [SyncEngine]
  /// treats each event as a hint to pull soon; it does not need to carry
  /// any payload.
  Stream<void> get remoteChangeSignal;
}
