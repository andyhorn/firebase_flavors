import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../bin/src/models/global_config.dart';
import '../../bin/src/services/firebase_project_service.dart';
import '../utils/mocks.dart';

GlobalConfig _config({Map<String, String>? flavors}) {
  final flavorBlock = (flavors ?? {'dev': 'dev', 'prod': 'prod'}).entries
      .map(
        (e) =>
            '''
  ${e.key}:
    firebaseProjectId: # unset
    androidSrcDir: ${e.value}
    iosConfigDir: ${e.value}''',
      )
      .join('\n');
  return GlobalConfig.fromYaml(
    loadYaml('''
appName: Test
baseBundleId: com.example.app
flavors:
$flavorBlock
''')
        as YamlMap,
  );
}

void main() {
  group('extractFromGoogleServices', () {
    late MockFileSystem fs;
    late FirebaseProjectService service;

    setUp(() {
      fs = MockFileSystem();
      service = FirebaseProjectService(fileSystem: fs);
    });

    test('returns the project_id field from valid google-services.json', () {
      fs.addFile('a/google-services.json', '''
{
  "project_info": {"project_id": "my-android-project"},
  "project_id": "my-android-project"
}
''');

      expect(
        service.extractFromGoogleServices('a/google-services.json'),
        equals('my-android-project'),
      );
    });

    test('returns null when file does not exist', () {
      expect(service.extractFromGoogleServices('missing.json'), isNull);
    });

    test('returns null when project_id is missing', () {
      fs.addFile('a.json', '{"project_info": {"name": "x"}}');

      expect(service.extractFromGoogleServices('a.json'), isNull);
    });

    test('returns null when project_id is empty', () {
      fs.addFile('a.json', '{"project_id": ""}');

      expect(service.extractFromGoogleServices('a.json'), isNull);
    });

    test('returns null on malformed JSON', () {
      fs.addFile('a.json', 'this is not json');

      expect(service.extractFromGoogleServices('a.json'), isNull);
    });
  });

  group('extractFromGoogleServiceInfo', () {
    late MockFileSystem fs;
    late FirebaseProjectService service;

    setUp(() {
      fs = MockFileSystem();
      service = FirebaseProjectService(fileSystem: fs);
    });

    test('returns PROJECT_ID from a plist with the standard layout', () {
      fs.addFile('p.plist', '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>PROJECT_ID</key>
  <string>my-ios-project</string>
</dict>
</plist>
''');

      expect(
        service.extractFromGoogleServiceInfo('p.plist'),
        equals('my-ios-project'),
      );
    });

    test('matches case-insensitively', () {
      fs.addFile('p.plist', '''
<key>project_id</key><string>case-insensitive</string>
''');

      expect(
        service.extractFromGoogleServiceInfo('p.plist'),
        equals('case-insensitive'),
      );
    });

    test('returns null when file does not exist', () {
      expect(service.extractFromGoogleServiceInfo('missing.plist'), isNull);
    });

    test('returns null when PROJECT_ID is absent', () {
      fs.addFile('p.plist', '<plist><dict></dict></plist>');

      expect(service.extractFromGoogleServiceInfo('p.plist'), isNull);
    });
  });

  group('detectFromConfigFiles', () {
    test('prefers Android config when both platforms have a file', () {
      final fs = MockFileSystem()
        ..addFile(
          'android/app/src/dev/google-services.json',
          '{"project_id": "android-dev"}',
        )
        ..addFile(
          'ios/Runner/dev/GoogleService-Info.plist',
          '<key>PROJECT_ID</key><string>ios-dev</string>',
        );
      final service = FirebaseProjectService(fileSystem: fs);

      final detected = service.detectFromConfigFiles(_config());

      expect(detected['dev'], equals('android-dev'));
    });

    test('falls back to iOS when Android file is absent', () {
      final fs = MockFileSystem()
        ..addFile(
          'ios/Runner/dev/GoogleService-Info.plist',
          '<key>PROJECT_ID</key><string>ios-dev</string>',
        );
      final service = FirebaseProjectService(fileSystem: fs);

      final detected = service.detectFromConfigFiles(_config());

      expect(detected['dev'], equals('ios-dev'));
    });

    test('omits flavors with no detectable project ID', () {
      final fs = MockFileSystem()
        ..addFile(
          'android/app/src/dev/google-services.json',
          '{"project_id": "android-dev"}',
        );
      final service = FirebaseProjectService(fileSystem: fs);

      final detected = service.detectFromConfigFiles(_config());

      expect(detected, equals({'dev': 'android-dev'}));
      expect(detected.containsKey('prod'), isFalse);
    });
  });

  group('listProjects', () {
    test('parses Firebase CLI JSON output into FirebaseProject list', () async {
      final runner = MockProcessRunner();
      runner.setRunResult(
        'firebase',
        ProcessResult(0, 0, '''
{
  "result": [
    {"projectId": "alpha", "displayName": "Alpha App"},
    {"projectId": "beta", "displayName": "Beta App"}
  ]
}''', ''),
      );
      final service = FirebaseProjectService(processRunner: runner);

      final projects = await service.listProjects();

      expect(projects, hasLength(2));
      expect(projects[0].projectId, equals('alpha'));
      expect(projects[0].displayName, equals('Alpha App'));
      expect(projects[1].projectId, equals('beta'));
    });

    test('falls back to projectId when displayName is missing', () async {
      final runner = MockProcessRunner();
      runner.setRunResult(
        'firebase',
        ProcessResult(0, 0, '{"result": [{"projectId": "only-id"}]}', ''),
      );
      final service = FirebaseProjectService(processRunner: runner);

      final projects = await service.listProjects();

      expect(projects, hasLength(1));
      expect(projects[0].displayName, equals('only-id'));
    });

    test('returns empty list when CLI exits non-zero', () async {
      final runner = MockProcessRunner();
      runner.setRunResult(
        'firebase',
        ProcessResult(0, 1, '', 'not authenticated'),
      );
      final service = FirebaseProjectService(processRunner: runner);

      expect(await service.listProjects(), isEmpty);
    });

    test('returns empty list on malformed JSON output', () async {
      final runner = MockProcessRunner();
      runner.setRunResult('firebase', ProcessResult(0, 0, 'not json', ''));
      final service = FirebaseProjectService(processRunner: runner);

      expect(await service.listProjects(), isEmpty);
    });

    test('returns empty list when result key is missing', () async {
      final runner = MockProcessRunner();
      runner.setRunResult('firebase', ProcessResult(0, 0, '{}', ''));
      final service = FirebaseProjectService(processRunner: runner);

      expect(await service.listProjects(), isEmpty);
    });

    test('skips projects with empty projectId', () async {
      final runner = MockProcessRunner();
      runner.setRunResult(
        'firebase',
        ProcessResult(
          0,
          0,
          '{"result": [{"projectId": "", "displayName": "Empty"}, '
              '{"projectId": "ok", "displayName": "OK"}]}',
          '',
        ),
      );
      final service = FirebaseProjectService(processRunner: runner);

      final projects = await service.listProjects();

      expect(projects, hasLength(1));
      expect(projects[0].projectId, equals('ok'));
    });
  });
}
