import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../bin/src/models/flavor_config.dart';

void main() {
  group('FlavorConfig.fromYaml', () {
    test('parses minimal required fields', () {
      final yaml =
          loadYaml('''
name: dev
firebaseProjectId: test-project-id
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.name, equals('dev'));
      expect(config.firebaseProjectId, equals('test-project-id'));
      expect(config.androidPackageSuffix, isNull);
      expect(config.dartOptionsOut, equals('lib/firebase_options_dev.dart'));
      expect(config.androidSrcDir, equals('dev'));
      expect(config.iosConfigDir, equals('dev'));
      expect(config.platforms, isNull);
      expect(config.iosBundleSuffix, isNull);
    });

    test('parses all fields when provided', () {
      final yaml =
          loadYaml('''
name: staging
firebaseProjectId: staging-project-id
androidPackageSuffix: .stg
dartOptionsOut: lib/custom_options_staging.dart
androidSrcDir: staging_android
iosConfigDir: staging_ios
platforms: android,ios
iosBundleSuffix: .stg
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.name, equals('staging'));
      expect(config.firebaseProjectId, equals('staging-project-id'));
      expect(config.androidPackageSuffix, equals('.stg'));
      expect(config.dartOptionsOut, equals('lib/custom_options_staging.dart'));
      expect(config.androidSrcDir, equals('staging_android'));
      expect(config.iosConfigDir, equals('staging_ios'));
      expect(config.platforms, equals('android,ios'));
      expect(config.iosBundleSuffix, equals('.stg'));
    });

    test('throws ArgumentError when firebaseProjectId is missing', () {
      final yaml =
          loadYaml('''
name: dev
''')
              as YamlMap;

      expect(
        () => FlavorConfig.fromYaml(yaml),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('firebaseProjectId is required'),
          ),
        ),
      );
    });

    test('throws ArgumentError when firebaseProjectId is empty', () {
      final yaml =
          loadYaml('''
name: dev
firebaseProjectId: ''
''')
              as YamlMap;

      expect(
        () => FlavorConfig.fromYaml(yaml),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('firebaseProjectId is required'),
          ),
        ),
      );
    });

    test('normalizes androidPackageSuffix with leading dot', () {
      final yaml =
          loadYaml('''
name: dev
firebaseProjectId: test-project
androidPackageSuffix: .dev
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, equals('.dev'));
    });

    test('normalizes androidPackageSuffix without leading dot', () {
      final yaml =
          loadYaml('''
name: dev
firebaseProjectId: test-project
androidPackageSuffix: dev
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, equals('.dev'));
    });

    test('sets androidPackageSuffix to null when empty', () {
      final yaml =
          loadYaml('''
name: prod
firebaseProjectId: test-project
androidPackageSuffix: ''
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, isNull);
    });

    test('sets androidPackageSuffix to null when not provided', () {
      final yaml =
          loadYaml('''
name: prod
firebaseProjectId: test-project
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidPackageSuffix, isNull);
    });

    test('uses default dartOptionsOut when not provided', () {
      final yaml =
          loadYaml('''
name: custom
firebaseProjectId: test-project
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.dartOptionsOut, equals('lib/firebase_options_custom.dart'));
    });

    test('uses default androidSrcDir when not provided', () {
      final yaml =
          loadYaml('''
name: custom
firebaseProjectId: test-project
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.androidSrcDir, equals('custom'));
    });

    test('uses default iosConfigDir when not provided', () {
      final yaml =
          loadYaml('''
name: custom
firebaseProjectId: test-project
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosConfigDir, equals('custom'));
    });

    test('normalizes iosBundleSuffix with leading dot', () {
      final yaml =
          loadYaml('''
name: dev
firebaseProjectId: test-project
iosBundleSuffix: .dev
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosBundleSuffix, equals('.dev'));
    });

    test('normalizes iosBundleSuffix without leading dot', () {
      final yaml =
          loadYaml('''
name: dev
firebaseProjectId: test-project
iosBundleSuffix: dev
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosBundleSuffix, equals('.dev'));
    });

    test('sets iosBundleSuffix to null when empty', () {
      final yaml =
          loadYaml('''
name: prod
firebaseProjectId: test-project
iosBundleSuffix: ''
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosBundleSuffix, isNull);
    });

    test('sets iosBundleSuffix to null when not provided', () {
      final yaml =
          loadYaml('''
name: prod
firebaseProjectId: test-project
''')
              as YamlMap;

      final config = FlavorConfig.fromYaml(yaml);

      expect(config.iosBundleSuffix, isNull);
    });
  });

  group('FlavorConfig bundle ID helpers', () {
    test('getAndroidBundleId appends suffix to base bundle ID', () {
      final config = FlavorConfig(
        name: 'dev',
        firebaseProjectId: 'test-project',
        androidPackageSuffix: '.dev',
        dartOptionsOut: 'lib/firebase_options_dev.dart',
        androidSrcDir: 'dev',
        iosConfigDir: 'dev',
        platforms: null,
      );

      expect(
        config.getAndroidBundleId('com.example.app'),
        equals('com.example.app.dev'),
      );
    });

    test('getAndroidBundleId returns base bundle ID when suffix is null', () {
      final config = FlavorConfig(
        name: 'prod',
        firebaseProjectId: 'test-project',
        androidPackageSuffix: null,
        dartOptionsOut: 'lib/firebase_options_prod.dart',
        androidSrcDir: 'prod',
        iosConfigDir: 'prod',
        platforms: null,
      );

      expect(
        config.getAndroidBundleId('com.example.app'),
        equals('com.example.app'),
      );
    });

    test('getIosBundleId appends suffix to base bundle ID', () {
      final config = FlavorConfig(
        name: 'dev',
        firebaseProjectId: 'test-project',
        androidPackageSuffix: null,
        dartOptionsOut: 'lib/firebase_options_dev.dart',
        androidSrcDir: 'dev',
        iosConfigDir: 'dev',
        platforms: null,
        iosBundleSuffix: '.dev',
      );

      expect(
        config.getIosBundleId('com.example.app'),
        equals('com.example.app.dev'),
      );
    });

    test('getIosBundleId returns base bundle ID when suffix is null', () {
      final config = FlavorConfig(
        name: 'prod',
        firebaseProjectId: 'test-project',
        androidPackageSuffix: null,
        dartOptionsOut: 'lib/firebase_options_prod.dart',
        androidSrcDir: 'prod',
        iosConfigDir: 'prod',
        platforms: null,
        iosBundleSuffix: null,
      );

      expect(
        config.getIosBundleId('com.example.app'),
        equals('com.example.app'),
      );
    });
  });
}
