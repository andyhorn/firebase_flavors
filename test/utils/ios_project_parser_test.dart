import 'dart:io';

import 'package:test/test.dart';

import '../../bin/src/utils/ios_project_parser.dart';

void main() {
  group('IosProjectParser.extractFromPbxproj', () {
    late String runnerPbxproj;

    setUpAll(() {
      runnerPbxproj = File('test/fixtures/runner.pbxproj').readAsStringSync();
    });

    test('extracts target name and bundle ID from a real Flutter pbxproj', () {
      final result = IosProjectParser.extractFromPbxproj(runnerPbxproj);

      expect(result.targetName, equals('Runner'));
      expect(result.bundleId, equals('io.flutter.examples.hello-world'));
    });

    test('returns null fields for empty content', () {
      final result = IosProjectParser.extractFromPbxproj('');

      expect(result.targetName, isNull);
      expect(result.bundleId, isNull);
    });

    test('returns null fields when content has no native targets', () {
      // Minimal valid pbxproj with no PBXNativeTarget section.
      const content = '''
// !\$*UTF8*\$!
{
	archiveVersion = 1;
	objectVersion = 55;
	objects = {
	};
	rootObject = ABCDEF /* Project object */;
}
''';

      final result = IosProjectParser.extractFromPbxproj(content);

      expect(result.targetName, isNull);
      expect(result.bundleId, isNull);
    });

    test('skips bundle IDs containing variable references', () {
      // Synthesize a pbxproj where the only PRODUCT_BUNDLE_IDENTIFIER is a
      // $(...) reference — should yield bundleId == null even though a
      // matching app target exists.
      final mutated = runnerPbxproj.replaceAll(
        'io.flutter.examples.hello-world',
        r'$(PRODUCT_BUNDLE_IDENTIFIER:rfc1034identifier)',
      );

      final result = IosProjectParser.extractFromPbxproj(mutated);

      expect(result.targetName, equals('Runner'));
      expect(result.bundleId, isNull);
    });
  });

  group('IosProjectParser.extractAppNameFromInfoPlist', () {
    test('extracts CFBundleDisplayName when present', () {
      const plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>My App</string>
  <key>CFBundleName</key>
  <string>my_app</string>
</dict>
</plist>
''';

      expect(
        IosProjectParser.extractAppNameFromInfoPlist(plist),
        equals('My App'),
      );
    });

    test('falls back to CFBundleName when CFBundleDisplayName is absent', () {
      const plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>my_app</string>
</dict>
</plist>
''';

      expect(
        IosProjectParser.extractAppNameFromInfoPlist(plist),
        equals('my_app'),
      );
    });

    test('returns null when neither key is present', () {
      const plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
</dict>
</plist>
''';

      expect(IosProjectParser.extractAppNameFromInfoPlist(plist), isNull);
    });

    test('trims whitespace around the value', () {
      const plist = '''
<key>CFBundleDisplayName</key>
<string>  Padded Name  </string>
''';

      expect(
        IosProjectParser.extractAppNameFromInfoPlist(plist),
        equals('Padded Name'),
      );
    });

    test('matches case-insensitively', () {
      const plist = '''
<key>cfbundledisplayname</key>
<string>case-insensitive</string>
''';

      expect(
        IosProjectParser.extractAppNameFromInfoPlist(plist),
        equals('case-insensitive'),
      );
    });
  });
}
