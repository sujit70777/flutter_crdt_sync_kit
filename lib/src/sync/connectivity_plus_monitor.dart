import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_monitor.dart';

/// A [ConnectivityMonitor] backed by `package:connectivity_plus`.
///
/// This only reports whether an interface (wifi/cellular/ethernet) is
/// connected, not whether it actually has internet access — [SyncEngine]'s
/// retry/backoff handles the case where the interface is up but the
/// backend is unreachable.
class ConnectivityPlusMonitor implements ConnectivityMonitor {
  final Connectivity _connectivity;

  ConnectivityPlusMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> get isOnline async =>
      _isOnline(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();
}
