import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_sync_kit_method_channel.dart';

abstract class FlutterSyncKitPlatform extends PlatformInterface {
  /// Constructs a FlutterSyncKitPlatform.
  FlutterSyncKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSyncKitPlatform _instance = MethodChannelFlutterSyncKit();

  /// The default instance of [FlutterSyncKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSyncKit].
  static FlutterSyncKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSyncKitPlatform] when
  /// they register themselves.
  static set instance(FlutterSyncKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
