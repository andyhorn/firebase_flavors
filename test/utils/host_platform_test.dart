import 'package:platform/platform.dart';

import 'package:test/test.dart';

import '../../bin/src/utils/host_platform.dart';

void main() {
  test('configuration changes based on platform', () {
    // TODO override platform.
    expect(HostPlatformConfig.flutterfireCli, equals('flutterfire'));
    // TODO override platform.
    expect(HostPlatformConfig.flutterfireCli, equals('flutterfire.bat'));
  });
}
