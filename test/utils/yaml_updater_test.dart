import 'package:test/test.dart';

import '../../bin/src/utils/yaml_updater.dart';
import 'mocks.dart';

const _sampleYaml = '''
appName: Test App
baseBundleId: com.example.app

flavors:
  dev:
    firebaseProjectId: # Run: firebase_flavors set-project-ids
    androidPackageSuffix: dev
  staging:
    firebaseProjectId: existing-staging-id
    androidPackageSuffix: staging
  prod:
    firebaseProjectId:
    androidPackageSuffix:
''';

void main() {
  group('YamlUpdater.updateProjectId', () {
    late MockFileSystem fs;
    late YamlUpdater updater;

    setUp(() {
      fs = MockFileSystem();
      fs.addFile('config.yaml', _sampleYaml);
      updater = YamlUpdater(fileSystem: fs);
    });

    test('writes a new project ID into an empty field', () {
      final ok = updater.updateProjectId('config.yaml', 'dev', 'real-dev-id');

      expect(ok, isTrue);
      expect(
        fs.readFile('config.yaml'),
        contains('firebaseProjectId: real-dev-id'),
      );
    });

    test('preserves the trailing comment when populating empty value', () {
      updater.updateProjectId('config.yaml', 'dev', 'real-dev-id');

      expect(
        fs.readFile('config.yaml'),
        contains(
          'firebaseProjectId: real-dev-id # Run: firebase_flavors set-project-ids',
        ),
      );
    });

    test('replaces an existing non-empty project ID', () {
      final ok = updater.updateProjectId(
        'config.yaml',
        'staging',
        'new-staging-id',
      );

      expect(ok, isTrue);
      final content = fs.readFile('config.yaml');
      expect(content, contains('firebaseProjectId: new-staging-id'));
      expect(
        content,
        isNot(contains('firebaseProjectId: existing-staging-id')),
      );
    });

    test('returns false and warns when flavor is missing', () {
      final ok = updater.updateProjectId(
        'config.yaml',
        'nonexistent',
        'whatever',
      );

      expect(ok, isFalse);
      // Original content unchanged.
      expect(fs.readFile('config.yaml'), equals(_sampleYaml));
    });

    test('returns false when the config file does not exist', () {
      final ok = updater.updateProjectId('missing.yaml', 'dev', 'whatever');

      expect(ok, isFalse);
    });

    test('preserves other flavors after update', () {
      updater.updateProjectId('config.yaml', 'dev', 'real-dev-id');

      final content = fs.readFile('config.yaml');
      expect(content, contains('firebaseProjectId: existing-staging-id'));
      expect(content, contains('staging:'));
      expect(content, contains('prod:'));
    });
  });

  group('YamlUpdater.updateProjectIds', () {
    test('returns the count of successful updates', () {
      final fs = MockFileSystem()..addFile('config.yaml', _sampleYaml);
      final updater = YamlUpdater(fileSystem: fs);

      final count = updater.updateProjectIds('config.yaml', {
        'dev': 'd',
        'staging': 's',
        'nonexistent': 'x',
      });

      expect(count, equals(2));
      final content = fs.readFile('config.yaml');
      expect(content, contains('firebaseProjectId: d'));
      expect(content, contains('firebaseProjectId: s'));
    });
  });
}
