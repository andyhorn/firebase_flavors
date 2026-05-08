import 'dart:io';

import 'exceptions.dart';
import 'logger.dart';
import 'utils/gradle_parser.dart';
import 'utils/ios_project_parser.dart';
import 'utils/yaml_generator.dart';

/// Holds all detected values from Android or iOS project files.
class _DetectionResult {
  _DetectionResult({
    this.baseBundleId,
    this.flavors = const [],
    this.flavorSuffixes = const {},
    this.appName,
    this.iosTarget,
  });

  final String? baseBundleId;
  final List<String> flavors;
  final Map<String, String> flavorSuffixes; // flavor -> suffix
  final String? appName;
  final String? iosTarget;
}

Future<void> init({bool force = false, required String configPath}) async {
  final yamlFile = File(configPath);

  if (yamlFile.existsSync() && !force) {
    throw FirebaseFlavorsException(
      'firebase_flavors.yaml already exists.\n'
      'Use `firebase_flavors init --force` to overwrite.',
    );
  }

  if (force && yamlFile.existsSync()) {
    logWarning(
      'Overwriting existing firebase_flavors.yaml (--force flag used)',
    );
  }

  logInfo('Detecting project configuration...');

  // Try Android first, then iOS as fallback
  _DetectionResult? result;
  final gradleFile = File('android/app/build.gradle');
  final gradleKtsFile = File('android/app/build.gradle.kts');

  if (gradleFile.existsSync() || gradleKtsFile.existsSync()) {
    logDebug('Found Android Gradle file, attempting detection...');
    result = _detectFromAndroidGradle(gradleFile, gradleKtsFile);
    if (result != null) {
      logInfo('Android detection successful');
      if (result.flavors.isNotEmpty) {
        logDebug('Detected flavors from Android: ${result.flavors.join(', ')}');
      }
      if (result.baseBundleId != null) {
        logDebug(
          'Detected base bundle ID from Android: ${result.baseBundleId}',
        );
      }
    } else {
      logDebug('Android detection did not find configuration');
    }
  }

  // Fallback to iOS if Android detection didn't find flavors or bundle ID
  if (result == null ||
      (result.flavors.isEmpty && result.baseBundleId == null)) {
    logDebug('Attempting iOS project detection...');
    final iosResult = _detectFromIOSProject();
    if (iosResult != null) {
      logInfo('iOS detection successful');
      // Merge results, preferring Android values
      result = _DetectionResult(
        baseBundleId: result?.baseBundleId ?? iosResult.baseBundleId,
        flavors: result?.flavors.isNotEmpty == true
            ? result!.flavors
            : iosResult.flavors,
        flavorSuffixes: result?.flavorSuffixes ?? iosResult.flavorSuffixes,
        appName: result?.appName ?? iosResult.appName,
        iosTarget: iosResult.iosTarget,
      );
      if (iosResult.flavors.isNotEmpty) {
        logDebug('Detected flavors from iOS: ${iosResult.flavors.join(', ')}');
      }
      if (iosResult.baseBundleId != null) {
        logDebug('Detected base bundle ID from iOS: ${iosResult.baseBundleId}');
      }
    } else {
      logDebug('iOS detection did not find configuration');
    }
  }

  // Use defaults if nothing was detected
  final flavors = result?.flavors.isNotEmpty == true
      ? result!.flavors
      : ['dev', 'staging', 'prod'];
  final baseBundleId = result?.baseBundleId ?? 'com.example.app';
  final appName = result?.appName ?? 'your_app_name_here';
  final flavorSuffixes = result?.flavorSuffixes ?? {};

  if (result == null ||
      (result.flavors.isEmpty && result.baseBundleId == null)) {
    logWarning('No project configuration detected, using defaults');
  }

  logInfo('Generating configuration file...');
  final yamlContent = YamlGenerator.generateContent(
    baseBundleId: baseBundleId,
    appName: appName,
    flavors: flavors,
    flavorSuffixes: flavorSuffixes,
    iosTarget: result?.iosTarget,
  );

  yamlFile.writeAsStringSync(yamlContent);
  logDebug('Configuration file written to: ${yamlFile.path}');

  logSuccess('Created firebase_flavors.yaml');
  logInfo('Detected flavors: ${flavors.join(', ')}');
  if (result?.baseBundleId != null) {
    final source = gradleFile.existsSync() || gradleKtsFile.existsSync()
        ? 'Android'
        : 'iOS';
    logInfo('Detected base bundle ID from $source: ${result!.baseBundleId}');
  } else {
    logWarning(
      'Base bundle ID defaulted to $baseBundleId (edit this in firebase_flavors.yaml).',
    );
  }
}

/// Detects values from Android Gradle files (build.gradle or build.gradle.kts).
_DetectionResult? _detectFromAndroidGradle(
  File gradleFile,
  File gradleKtsFile,
) {
  File? file;
  bool isKts = false;

  if (gradleKtsFile.existsSync()) {
    file = gradleKtsFile;
    isKts = true;
  } else if (gradleFile.existsSync()) {
    file = gradleFile;
    isKts = false;
  } else {
    return null;
  }

  try {
    logDebug('Reading Gradle file: ${file.path}');
    final content = file.readAsStringSync();
    final baseBundleId = GradleParser.extractApplicationId(content);
    final flavorData = GradleParser.extractProductFlavors(content, isKts);
    final appName = GradleParser.extractAppName(content);

    if (baseBundleId != null) {
      logDebug('Extracted application ID: $baseBundleId');
    }
    if (flavorData.isNotEmpty) {
      logDebug('Extracted ${flavorData.length} product flavor(s)');
    }
    if (appName != null) {
      logDebug('Extracted app name: $appName');
    }

    return _DetectionResult(
      baseBundleId: baseBundleId,
      flavors: flavorData.keys.toList(),
      flavorSuffixes: flavorData,
      appName: appName,
    );
  } catch (e) {
    logDebug('Failed to parse Android Gradle file: $e');
    // Silently fail and return null to allow fallback to iOS
    return null;
  }
}

/// Detects values from iOS project files (project.pbxproj and Info.plist).
_DetectionResult? _detectFromIOSProject() {
  // Try to find the Xcode project
  final iosDir = Directory('ios');
  if (!iosDir.existsSync()) {
    logDebug('iOS directory not found');
    return null;
  }

  logDebug('iOS directory found, searching for project files...');

  // Find project.pbxproj file
  File? pbxprojFile;
  final runnerDir = Directory('ios/Runner.xcodeproj');
  if (runnerDir.existsSync()) {
    pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
    if (!pbxprojFile.existsSync()) {
      // Try to find any .xcodeproj directory
      final xcodeprojDirs = iosDir.listSync().whereType<Directory>().where(
        (dir) => dir.path.endsWith('.xcodeproj'),
      );
      if (xcodeprojDirs.isNotEmpty) {
        final xcodeprojDir = xcodeprojDirs.first;
        pbxprojFile = File('${xcodeprojDir.path}/project.pbxproj');
      }
    }
  }

  String? baseBundleId;
  String? appName;
  String? iosTarget;

  if (pbxprojFile != null && pbxprojFile.existsSync()) {
    logDebug('Found project.pbxproj: ${pbxprojFile.path}');
    try {
      final extracted = IosProjectParser.extractFromPbxproj(
        pbxprojFile.readAsStringSync(),
      );
      baseBundleId = extracted.bundleId;
      iosTarget = extracted.targetName;
      if (baseBundleId != null) {
        logDebug('Extracted bundle ID from project.pbxproj: $baseBundleId');
      }
      if (iosTarget != null) {
        logDebug('Extracted target: $iosTarget');
      }
    } catch (e) {
      logDebug('Failed to parse project.pbxproj: $e');
    }
  }

  // Read app name from the target's Info.plist if present at the canonical
  // path. Bundle ID is not read from Info.plist — modern Flutter projects
  // store it as $(PRODUCT_BUNDLE_IDENTIFIER), and pbxproj is authoritative.
  final infoPlistFile = File('ios/${iosTarget ?? 'Runner'}/Info.plist');
  if (infoPlistFile.existsSync()) {
    logDebug('Found Info.plist: ${infoPlistFile.path}');
    try {
      appName = IosProjectParser.extractAppNameFromInfoPlist(
        infoPlistFile.readAsStringSync(),
      );
      if (appName != null) {
        logDebug('Extracted app name from Info.plist: $appName');
      }
    } catch (e) {
      logDebug('Failed to parse Info.plist: $e');
    }
  }

  // If we found at least something, return a result
  if (baseBundleId != null || appName != null) {
    return _DetectionResult(
      baseBundleId: baseBundleId,
      flavors: const [],
      appName: appName,
      iosTarget: iosTarget ?? 'Runner',
    );
  }

  return null;
}
