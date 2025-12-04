import 'package:test/test.dart';

import '../../bin/src/utils/config_reader.dart';

void main() {
  group('ConfigReader.normalizePlatforms', () {
    test('returns empty list for null input', () {
      final result = ConfigReader.normalizePlatforms(null);

      expect(result, isEmpty);
    });

    test('returns empty list for empty string', () {
      final result = ConfigReader.normalizePlatforms('');

      expect(result, isEmpty);
    });

    test('normalizes single platform', () {
      final result = ConfigReader.normalizePlatforms('android');

      expect(result, equals(['android']));
    });

    test('normalizes multiple platforms', () {
      final result = ConfigReader.normalizePlatforms('android,ios');

      expect(result, equals(['android', 'ios']));
    });

    test('converts to lowercase', () {
      final result = ConfigReader.normalizePlatforms('ANDROID,IOS,WEB');

      expect(result, equals(['android', 'ios', 'web']));
    });

    test('trims whitespace', () {
      final result = ConfigReader.normalizePlatforms(' android , ios , web ');

      expect(result, equals(['android', 'ios', 'web']));
    });

    test('handles mixed case and whitespace', () {
      final result = ConfigReader.normalizePlatforms(' Android , iOS , Web ');

      expect(result, equals(['android', 'ios', 'web']));
    });

    test('filters out empty strings', () {
      final result = ConfigReader.normalizePlatforms('android,,ios');

      expect(result, equals(['android', 'ios']));
    });

    test('handles only whitespace as empty', () {
      final result = ConfigReader.normalizePlatforms('android,  ,ios');

      expect(result, equals(['android', 'ios']));
    });

    test('handles multiple commas', () {
      final result = ConfigReader.normalizePlatforms('android,,,ios');

      expect(result, equals(['android', 'ios']));
    });

    test('handles trailing comma', () {
      final result = ConfigReader.normalizePlatforms('android,ios,');

      expect(result, equals(['android', 'ios']));
    });

    test('handles leading comma', () {
      final result = ConfigReader.normalizePlatforms(',android,ios');

      expect(result, equals(['android', 'ios']));
    });

    test('handles three platforms', () {
      final result = ConfigReader.normalizePlatforms('android,ios,web');

      expect(result, equals(['android', 'ios', 'web']));
    });

    test('handles macos platform', () {
      final result = ConfigReader.normalizePlatforms('android,ios,web,macos');

      expect(result, equals(['android', 'ios', 'web', 'macos']));
    });
  });
}
