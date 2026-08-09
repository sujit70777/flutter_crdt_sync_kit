import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_sync_kit_platform_interface.dart';

/// An implementation of [FlutterSyncKitPlatform] that uses method channels.
class MethodChannelFlutterSyncKit extends FlutterSyncKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_sync_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
