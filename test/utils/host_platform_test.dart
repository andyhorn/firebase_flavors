import 'package:platform/platform.dart';
import 'package:test/test.dart';

import '../../bin/src/utils/host_platform.dart';

void main() {
  test('flutterfire config changes based on platform', () {
    HostPlatformConfig.overridePlatform(FakePlatform(operatingSystem: 'macos'));
    expect(HostPlatformConfig.flutterfireCli, equals('flutterfire'));

    HostPlatformConfig.overridePlatform(
      FakePlatform(operatingSystem: 'windows'),
    );
    expect(HostPlatformConfig.flutterfireCli, equals('flutterfire.bat'));
  });

  test('pubspec cache config changes based on platform', () {
    HostPlatformConfig.overridePlatform(
      FakePlatform(operatingSystem: 'linux', environment: {'HOME': '/home/'}),
    );
    expect(HostPlatformConfig.pubCacheLocation, endsWith('/.pub/cache/bin'));

    HostPlatformConfig.overridePlatform(
      FakePlatform(
        operatingSystem: 'windows',
        environment: {'USERPROFILE': 'C:\\Users\\User.Name\\'},
      ),
    );
    expect(
      HostPlatformConfig.pubCacheLocation,
      endsWith('\\AppData\\Local\\Pub\\Cache\\bin'),
    );
  });
}
