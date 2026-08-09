import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sync_kit/flutter_sync_kit.dart';
import 'package:flutter_sync_kit/flutter_sync_kit_platform_interface.dart';
import 'package:flutter_sync_kit/flutter_sync_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSyncKitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSyncKitPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterSyncKitPlatform initialPlatform = FlutterSyncKitPlatform.instance;

  test('$MethodChannelFlutterSyncKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterSyncKit>());
  });

  test('getPlatformVersion', () async {
    FlutterSyncKit flutterSyncKitPlugin = FlutterSyncKit();
    MockFlutterSyncKitPlatform fakePlatform = MockFlutterSyncKitPlatform();
    FlutterSyncKitPlatform.instance = fakePlatform;

    expect(await flutterSyncKitPlugin.getPlatformVersion(), '42');
  });
}
