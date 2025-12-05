import 'dart:io';

import 'logger.dart';
import 'utils/gradle_parser.dart';
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
    logError(
      'firebase_flavors.yaml already exists.\n'
      'Use `firebase_flavors init --force` to overwrite.',
    );
    exit(1);
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

  // Find Info.plist file
  File? infoPlistFile;
  final runnerInfoPlist = File('ios/Runner/Info.plist');
  if (runnerInfoPlist.existsSync()) {
    infoPlistFile = runnerInfoPlist;
  } else {
    // Try to find Info.plist in any subdirectory
    final infoPlistFiles = iosDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('Info.plist'));
    if (infoPlistFiles.isNotEmpty) {
      infoPlistFile = infoPlistFiles.first;
    }
  }

  String? baseBundleId;
  String? appName;
  String? iosTarget;

  if (pbxprojFile != null && pbxprojFile.existsSync()) {
    logDebug('Found project.pbxproj: ${pbxprojFile.path}');
    try {
      baseBundleId ??= _extractBundleIdFromPbxproj(pbxprojFile);
      iosTarget = _extractTargetFromPbxproj(pbxprojFile);
      if (baseBundleId != null) {
        logDebug('Extracted bundle ID from project.pbxproj: $baseBundleId');
      }
      if (iosTarget != null) {
        logDebug('Extracted target: $iosTarget');
      }
    } catch (e) {
      logDebug('Failed to parse project.pbxproj: $e');
      // Continue to try Info.plist
    }
  }

  if (infoPlistFile != null && infoPlistFile.existsSync()) {
    logDebug('Found Info.plist: ${infoPlistFile.path}');
    try {
      baseBundleId ??= _extractBundleIdFromInfoPlist(infoPlistFile);
      appName ??= _extractAppNameFromInfoPlist(infoPlistFile);
      if (baseBundleId != null) {
        logDebug('Extracted bundle ID from Info.plist: $baseBundleId');
      }
      if (appName != null) {
        logDebug('Extracted app name from Info.plist: $appName');
      }
    } catch (e) {
      logDebug('Failed to parse Info.plist: $e');
      // Continue with what we have
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

/// Extracts bundle ID from project.pbxproj file.
String? _extractBundleIdFromPbxproj(File pbxprojFile) {
  final content = pbxprojFile.readAsStringSync();

  // Look for PRODUCT_BUNDLE_IDENTIFIER in build settings
  // Format: PRODUCT_BUNDLE_IDENTIFIER = "com.example.app";
  final bundleIdPattern =
      'PRODUCT_BUNDLE_IDENTIFIER\\s*[=:]\\s*["\']([^\'"]+)["\']';
  final bundleIdRegex = RegExp(bundleIdPattern, multiLine: true);

  // Find all matches and prefer the one in the main target (not in specific configs)
  final matches = bundleIdRegex.allMatches(content);
  for (final match in matches) {
    final bundleId = match.group(1)!;
    // Skip if it contains a variable reference like $(PRODUCT_BUNDLE_IDENTIFIER)
    if (!bundleId.contains('\$(')) {
      return bundleId;
    }
  }

  // If all have variables, return the first one anyway
  final firstMatch = bundleIdRegex.firstMatch(content);
  return firstMatch?.group(1);
}

/// Extracts target name from project.pbxproj file.
String? _extractTargetFromPbxproj(File pbxprojFile) {
  final content = pbxprojFile.readAsStringSync();

  // Look for PBXNativeTarget with name
  // Format: /* Runner */ = { ... name = Runner; ... }
  final targetPattern =
      r'/\*\s*([A-Za-z0-9_]+)\s*\*/\s*=\s*\{[^}]*name\s*=\s*\1';
  final targetRegex = RegExp(targetPattern, multiLine: true);
  final targetMatch = targetRegex.firstMatch(content);
  if (targetMatch != null) {
    return targetMatch.group(1);
  }

  // Fallback: look for any PBXNativeTarget
  final nativeTargetPattern = r'PBXNativeTarget[^}]*name\s*=\s*([A-Za-z0-9_]+)';
  final nativeTargetRegex = RegExp(nativeTargetPattern, multiLine: true);
  final nativeTargetMatch = nativeTargetRegex.firstMatch(content);
  return nativeTargetMatch?.group(1);
}

/// Extracts bundle ID from Info.plist file.
String? _extractBundleIdFromInfoPlist(File infoPlistFile) {
  final content = infoPlistFile.readAsStringSync();

  // XML format: <key>CFBundleIdentifier</key><string>com.example.app</string>
  final xmlBundleIdPattern =
      r'<key>\s*CFBundleIdentifier\s*</key>\s*<string>([^<]+)</string>';
  final xmlBundleIdRegex = RegExp(xmlBundleIdPattern, caseSensitive: false);
  final xmlMatch = xmlBundleIdRegex.firstMatch(content);
  if (xmlMatch != null) {
    return xmlMatch.group(1)?.trim();
  }

  // Plist format: CFBundleIdentifier = "com.example.app";
  final plistBundleIdRegex = RegExp(
    'CFBundleIdentifier\\s*[=:]\\s*["\']([^\'"]+)["\']',
    caseSensitive: false,
  );
  final plistMatch = plistBundleIdRegex.firstMatch(content);
  return plistMatch?.group(1);
}

/// Extracts app name from Info.plist file.
String? _extractAppNameFromInfoPlist(File infoPlistFile) {
  final content = infoPlistFile.readAsStringSync();

  // Try CFBundleDisplayName first (user-facing name)
  final displayNamePattern =
      r'<key>\s*CFBundleDisplayName\s*</key>\s*<string>([^<]+)</string>';
  final displayNameRegex = RegExp(displayNamePattern, caseSensitive: false);
  final displayNameMatch = displayNameRegex.firstMatch(content);
  if (displayNameMatch != null) {
    return displayNameMatch.group(1)?.trim();
  }

  // Fallback to CFBundleName
  final bundleNamePattern =
      r'<key>\s*CFBundleName\s*</key>\s*<string>([^<]+)</string>';
  final bundleNameRegex = RegExp(bundleNamePattern, caseSensitive: false);
  final bundleNameMatch = bundleNameRegex.firstMatch(content);
  if (bundleNameMatch != null) {
    return bundleNameMatch.group(1)?.trim();
  }

  return null;
}
