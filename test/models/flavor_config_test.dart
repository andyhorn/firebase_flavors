import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../bin/src/models/flavor_config.dart';

void main() {
  group('FlavorConfig.fromYaml', () {
    test('parses minimal required fields', () {
      final yaml = loadYaml('''
name: dev
firebaseProjectId: test-project-id
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.name, equals('dev'));
      expect(config.firebaseProjectId, equals('test-project-id'));
      expect(config.androidPackageSuffix, isNull);
      expect(config.dartOptionsOut, equals('lib/firebase_options_dev.dart'));
      expect(config.androidSrcDir, equals('dev'));
      expect(config.iosConfigDir, equals('dev'));
      expect(config.platforms, isNull);
      expect(config.iosBundleId, isNull);
    });

    test('parses all fields when provided', () {
      final yaml = loadYaml('''
name: staging
firebaseProjectId: staging-project-id
androidPackageSuffix: .stg
dartOptionsOut: lib/custom_options_staging.dart
androidSrcDir: staging_android
iosConfigDir: staging_ios
platforms: android,ios
iosBundleId: com.example.staging
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.name, equals('staging'));
      expect(config.firebaseProjectId, equals('staging-project-id'));
      expect(config.androidPackageSuffix, equals('.stg'));
      expect(config.dartOptionsOut, equals('lib/custom_options_staging.dart'));
      expect(config.androidSrcDir, equals('staging_android'));
      expect(config.iosConfigDir, equals('staging_ios'));
      expect(config.platforms, equals('android,ios'));
      expect(config.iosBundleId, equals('com.example.staging'));
    });

    test('throws ArgumentError when firebaseProjectId is missing', () {
      final yaml = loadYaml('''
name: dev
''') as YamlMap;

      expect(
        () => FlavorConfig.fromYaml(yaml),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('firebaseProjectId is required'),
        )),
      );
    });

    test('throws ArgumentError when firebaseProjectId is empty', () {
      final yaml = loadYaml('''
name: dev
firebaseProjectId: ''
''') as YamlMap;

      expect(
        () => FlavorConfig.fromYaml(yaml),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('firebaseProjectId is required'),
        )),
      );
    });

    test('normalizes androidPackageSuffix with leading dot', () {
      final yaml = loadYaml('''
name: dev
firebaseProjectId: test-project
androidPackageSuffix: .dev
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, equals('.dev'));
    });

    test('normalizes androidPackageSuffix without leading dot', () {
      final yaml = loadYaml('''
name: dev
firebaseProjectId: test-project
androidPackageSuffix: dev
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, equals('.dev'));
    });

    test('sets androidPackageSuffix to null when empty', () {
      final yaml = loadYaml('''
name: prod
firebaseProjectId: test-project
androidPackageSuffix: ''
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, isNull);
    });

    test('sets androidPackageSuffix to null when not provided', () {
      final yaml = loadYaml('''
name: prod
firebaseProjectId: test-project
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, isNull);
    });

    test('uses default dartOptionsOut when not provided', () {
      final yaml = loadYaml('''
name: custom
firebaseProjectId: test-project
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.dartOptionsOut, equals('lib/firebase_options_custom.dart'));
    });

    test('uses default androidSrcDir when not provided', () {
      final yaml = loadYaml('''
name: custom
firebaseProjectId: test-project
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidSrcDir, equals('custom'));
    });

    test('uses default iosConfigDir when not provided', () {
      final yaml = loadYaml('''
name: custom
firebaseProjectId: test-project
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosConfigDir, equals('custom'));
    });

    test('sets iosBundleId to null when empty string', () {
      final yaml = loadYaml('''
name: dev
firebaseProjectId: test-project
iosBundleId: ''
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosBundleId, isNull);
    });

    test('preserves iosBundleId when provided', () {
      final yaml = loadYaml('''
name: dev
firebaseProjectId: test-project
iosBundleId: com.example.custom
''') as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosBundleId, equals('com.example.custom'));
    });
  });
}

