import 'dart:async';

import 'package:flutter_sync_kit/flutter_sync_kit.dart';

/// A [ConnectivityMonitor] toggled by hand from the UI, standing in for
/// airplane mode — this is how the demo simulates each "device" going
/// offline and back online.
class ManualConnectivityMonitor implements ConnectivityMonitor {
  bool _online = true;
  final StreamController<bool> _controller = StreamController.broadcast();

  bool get online => _online;

  set online(bool value) {
    if (_online == value) return;
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onlineStream => _controller.stream;
}
