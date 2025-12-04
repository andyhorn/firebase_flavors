import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../bin/src/models/global_config.dart';

void main() {
  group('GlobalConfig.fromYaml', () {
    test('parses minimal required fields', () {
      final yaml = loadYaml('''
appName: Test App
baseBundleId: com.example.app
flavors: {}
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.appName, equals('Test App'));
      expect(config.baseBundleId, equals('com.example.app'));
      expect(config.androidSrcBase, equals('android/app/src'));
      expect(config.iosXcodeprojPath, equals('ios/Runner.xcodeproj'));
      expect(config.iosTarget, equals('Runner'));
      expect(config.iosConfigBase, equals('ios/Runner/Runner'));
      expect(config.flavors, isEmpty);
    });

    test('parses all fields when provided', () {
      final yaml = loadYaml('''
appName: My App
baseBundleId: com.example.myapp
android:
  srcBase: android/app/custom/src
ios:
  xcodeProjPath: ios/MyApp.xcodeproj
  target: MyApp
  configBase: ios/MyApp/Config
flavors:
  dev:
    firebaseProjectId: dev-project
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.appName, equals('My App'));
      expect(config.baseBundleId, equals('com.example.myapp'));
      expect(config.androidSrcBase, equals('android/app/custom/src'));
      expect(config.iosXcodeprojPath, equals('ios/MyApp.xcodeproj'));
      expect(config.iosTarget, equals('MyApp'));
      expect(config.iosConfigBase, equals('ios/MyApp/Config'));
      expect(config.flavors, hasLength(1));
      expect(config.flavors['dev'], isNotNull);
      expect(config.flavors['dev']!.firebaseProjectId, equals('dev-project'));
    });

    test('uses default android srcBase when not provided', () {
      final yaml = loadYaml('''
appName: Test App
baseBundleId: com.example.app
flavors: {}
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.androidSrcBase, equals('android/app/src'));
    });

    test('uses default iOS paths when not provided', () {
      final yaml = loadYaml('''
appName: Test App
baseBundleId: com.example.app
flavors: {}
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.iosXcodeprojPath, equals('ios/Runner.xcodeproj'));
      expect(config.iosTarget, equals('Runner'));
      expect(config.iosConfigBase, equals('ios/Runner/Runner'));
    });

    test('parses multiple flavors', () {
      final yaml = loadYaml('''
appName: Test App
baseBundleId: com.example.app
flavors:
  dev:
    firebaseProjectId: dev-project
  staging:
    firebaseProjectId: staging-project
  prod:
    firebaseProjectId: prod-project
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.flavors, hasLength(3));
      expect(config.flavors['dev'], isNotNull);
      expect(config.flavors['dev']!.firebaseProjectId, equals('dev-project'));
      expect(config.flavors['staging'], isNotNull);
      expect(config.flavors['staging']!.firebaseProjectId, equals('staging-project'));
      expect(config.flavors['prod'], isNotNull);
      expect(config.flavors['prod']!.firebaseProjectId, equals('prod-project'));
    });

    test('handles empty flavors map', () {
      final yaml = loadYaml('''
appName: Test App
baseBundleId: com.example.app
flavors: {}
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.flavors, isEmpty);
    });

    test('handles missing flavors key', () {
      final yaml = loadYaml('''
appName: Test App
baseBundleId: com.example.app
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.flavors, isEmpty);
    });

    test('handles partial iOS configuration', () {
      final yaml = loadYaml('''
appName: Test App
baseBundleId: com.example.app
ios:
  target: CustomTarget
flavors: {}
''') as YamlMap;

      final config = GlobalConfig.fromYaml(yaml);

      expect(config.iosTarget, equals('CustomTarget'));
      expect(config.iosXcodeprojPath, equals('ios/Runner.xcodeproj'));
      expect(config.iosConfigBase, equals('ios/Runner/Runner'));
    });
  });
}

