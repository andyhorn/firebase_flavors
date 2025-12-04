import 'package:test/test.dart';

import '../../bin/src/utils/ios_utils.dart';

void main() {
  group('IosUtils.configBaseRelativeToProjectDir', () {
    test('strips ios/ prefix', () {
      expect(
        IosUtils.configBaseRelativeToProjectDir('ios/Runner/Config'),
        equals('Runner/Config'),
      );
      expect(
        IosUtils.configBaseRelativeToProjectDir('ios/MyApp/Config'),
        equals('MyApp/Config'),
      );
    });

    test('preserves path without ios/ prefix', () {
      expect(
        IosUtils.configBaseRelativeToProjectDir('Runner/Config'),
        equals('Runner/Config'),
      );
      expect(
        IosUtils.configBaseRelativeToProjectDir('MyApp/Config'),
        equals('MyApp/Config'),
      );
    });

    test('handles root paths', () {
      expect(
        IosUtils.configBaseRelativeToProjectDir('Config'),
        equals('Config'),
      );
      expect(
        IosUtils.configBaseRelativeToProjectDir('ios/Config'),
        equals('Config'),
      );
    });
  });
}
