import 'package:test/test.dart';

import '../../bin/src/utils/yaml_generator.dart';

void main() {
  group('YamlGenerator.generateContent', () {
    test('generates minimal YAML content', () {
      final content = YamlGenerator.generateContent(
        baseBundleId: 'com.example.app',
        appName: 'Test App',
        flavors: ['dev', 'prod'],
        flavorSuffixes: {},
      );

      expect(content, contains('appName: Test App'));
      expect(content, contains('baseBundleId: com.example.app'));
      expect(content, contains('flavors:'));
      expect(content, contains('  dev:'));
      expect(content, contains('  prod:'));
    });

    test('includes detected flavor suffixes', () {
      final content = YamlGenerator.generateContent(
        baseBundleId: 'com.example.app',
        appName: 'Test App',
        flavors: ['dev', 'staging'],
        flavorSuffixes: {'dev': 'dev', 'staging': 'stg'},
      );

      expect(content, contains('androidPackageSuffix: dev'));
      expect(content, contains('androidPackageSuffix: stg'));
    });

    test('infers suffix for non-prod flavors', () {
      final content = YamlGenerator.generateContent(
        baseBundleId: 'com.example.app',
        appName: 'Test App',
        flavors: ['dev'],
        flavorSuffixes: {},
      );

      expect(content, contains('androidPackageSuffix: dev'));
    });

    test('uses empty suffix for prod-like flavors', () {
      final content = YamlGenerator.generateContent(
        baseBundleId: 'com.example.app',
        appName: 'Test App',
        flavors: ['prod', 'production'],
        flavorSuffixes: {},
      );

      expect(content, contains('androidPackageSuffix: '));
      expect(content, contains('prod:'));
      expect(content, contains('production:'));
    });

    test('includes iOS target when provided', () {
      final content = YamlGenerator.generateContent(
        baseBundleId: 'com.example.app',
        appName: 'Test App',
        flavors: ['dev'],
        flavorSuffixes: {},
        iosTarget: 'MyApp',
      );

      expect(content, contains('xcodeprojPath: ios/MyApp.xcodeproj'));
      expect(content, contains('target: MyApp'));
      expect(content, contains('configBase: ios/MyApp/Config'));
    });

    test('uses default Runner target when not provided', () {
      final content = YamlGenerator.generateContent(
        baseBundleId: 'com.example.app',
        appName: 'Test App',
        flavors: ['dev'],
        flavorSuffixes: {},
      );

      expect(content, contains('xcodeprojPath: ios/Runner.xcodeproj'));
      expect(content, contains('target: Runner'));
      expect(content, contains('configBase: ios/Runner/Config'));
    });

    test('includes all required flavor fields', () {
      final content = YamlGenerator.generateContent(
        baseBundleId: 'com.example.app',
        appName: 'Test App',
        flavors: ['dev'],
        flavorSuffixes: {},
      );

      expect(content, contains('firebaseProjectId:'));
      expect(content, contains('androidPackageSuffix:'));
      expect(content, contains('dartOptionsOut:'));
      expect(content, contains('androidSrcDir:'));
      expect(content, contains('iosConfigDir:'));
    });
  });
}
