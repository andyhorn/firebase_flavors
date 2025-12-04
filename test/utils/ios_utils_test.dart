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

  group('IosUtils.inferFlavorsFromBuildConfigs', () {
    test('extracts flavors from build config names', () {
      final configs = [
        'Debug-dev',
        'Release-dev',
        'Debug-staging',
        'Release-staging',
        'Debug-prod',
        'Release-prod',
      ];

      final result = IosUtils.inferFlavorsFromBuildConfigs(configs);

      expect(result, hasLength(3));
      expect(result, contains('dev'));
      expect(result, contains('staging'));
      expect(result, contains('prod'));
    });

    test('handles multi-part flavor names', () {
      final configs = [
        'Debug-production',
        'Release-production',
      ];

      final result = IosUtils.inferFlavorsFromBuildConfigs(configs);

      expect(result, hasLength(1));
      expect(result, contains('production'));
    });

    test('returns empty list for null input', () {
      final result = IosUtils.inferFlavorsFromBuildConfigs(null);

      expect(result, isEmpty);
    });

    test('returns empty list for empty input', () {
      final result = IosUtils.inferFlavorsFromBuildConfigs([]);

      expect(result, isEmpty);
    });

    test('ignores configs without dash separator', () {
      final configs = ['Debug', 'Release'];

      final result = IosUtils.inferFlavorsFromBuildConfigs(configs);

      expect(result, isEmpty);
    });

    test('sorts flavors alphabetically', () {
      final configs = [
        'Debug-zebra',
        'Debug-alpha',
        'Debug-beta',
      ];

      final result = IosUtils.inferFlavorsFromBuildConfigs(configs);

      expect(result, equals(['alpha', 'beta', 'zebra']));
    });

    test('handles Profile build type', () {
      final configs = [
        'Profile-dev',
        'Profile-staging',
      ];

      final result = IosUtils.inferFlavorsFromBuildConfigs(configs);

      expect(result, hasLength(2));
      expect(result, contains('dev'));
      expect(result, contains('staging'));
    });

    test('deduplicates flavors', () {
      final configs = [
        'Debug-dev',
        'Release-dev',
        'Profile-dev',
      ];

      final result = IosUtils.inferFlavorsFromBuildConfigs(configs);

      expect(result, hasLength(1));
      expect(result, contains('dev'));
    });
  });
}

