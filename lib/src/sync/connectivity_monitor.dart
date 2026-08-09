import 'dart:async';

/// Tells [SyncEngine] whether the device currently has network
/// connectivity, so it can avoid futile push/pull attempts and re-sync
/// promptly the moment connectivity returns.
///
/// sync_kit ships [AlwaysOnlineMonitor] (the default — always attempts to
/// sync, relying on push/pull failures for backoff) and
/// [ConnectivityPlusMonitor] (backed by `package:connectivity_plus`).
/// Provide your own implementation to integrate a different connectivity
/// source.
abstract class ConnectivityMonitor {
  /// Whether the device is online right now.
  Future<bool> get isOnline;

  /// Emits the current online state whenever it changes.
  Stream<bool> get onlineStream;
}

/// A [ConnectivityMonitor] that always reports online. [SyncEngine] will
/// still recover gracefully from push/pull failures via its retry policy,
/// so this is a perfectly reasonable default when you don't want to
/// depend on a connectivity plugin.
class AlwaysOnlineMonitor implements ConnectivityMonitor {
  const AlwaysOnlineMonitor();

  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<bool> get onlineStream => const Stream.empty();
}
