import 'dart:io';

import 'package:xcode_parser/xcode_parser.dart';

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

  String? baseBundleId;
  String? appName;
  String? iosTarget;

  if (pbxprojFile != null && pbxprojFile.existsSync()) {
    logDebug('Found project.pbxproj: ${pbxprojFile.path}');
    try {
      final extracted = _extractFromPbxproj(pbxprojFile);
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
      appName = _extractAppNameFromInfoPlist(infoPlistFile);
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

/// Extracts the main app target's name and bundle ID from a pbxproj file.
///
/// Walks the project graph: PBXNativeTarget where productType is the iOS
/// app type → its XCConfigurationList → first XCBuildConfiguration's
/// PRODUCT_BUNDLE_IDENTIFIER. This avoids picking up bundle IDs from
/// test, UI test, or extension targets.
({String? targetName, String? bundleId}) _extractFromPbxproj(File pbxprojFile) {
  final content = pbxprojFile.readAsStringSync();
  final project = Pbxproj.parse(content);
  final objects = project.find<MapPbx>('objects');
  if (objects == null) return (targetName: null, bundleId: null);

  SectionPbx? section(String name) {
    for (final c in objects.childrenList) {
      if (c is SectionPbx && c.uuid == name) return c;
    }
    return null;
  }

  final nativeTargets = section('PBXNativeTarget');
  if (nativeTargets == null) return (targetName: null, bundleId: null);

  MapPbx? appTarget;
  for (final t in nativeTargets.childrenList) {
    if (t is! MapPbx) continue;
    final pt = t.find<MapEntryPbx>('productType')?.value.toString() ?? '';
    if (pt.contains('com.apple.product-type.application')) {
      appTarget = t;
      break;
    }
  }
  if (appTarget == null) return (targetName: null, bundleId: null);

  final targetName = _unquote(
    appTarget.find<MapEntryPbx>('name')?.value.toString(),
  );

  final cfgListUuid = appTarget
      .find<MapEntryPbx>('buildConfigurationList')
      ?.value
      .toString();
  final cfgLists = section('XCConfigurationList');
  MapPbx? cfgList;
  for (final c in cfgLists?.childrenList ?? const []) {
    if (c is MapPbx && c.uuid == cfgListUuid) {
      cfgList = c;
      break;
    }
  }
  final buildCfgs = cfgList?.find<ListPbx>('buildConfigurations');
  if (buildCfgs == null || buildCfgs.isEmpty) {
    return (targetName: targetName, bundleId: null);
  }

  final buildConfigsSection = section('XCBuildConfiguration');
  String? bundleId;
  for (final el in buildCfgs.toList()) {
    final uuid = el.value.toString();
    MapPbx? cfg;
    for (final c in buildConfigsSection?.childrenList ?? const []) {
      if (c is MapPbx && c.uuid == uuid) {
        cfg = c;
        break;
      }
    }
    final raw = cfg
        ?.find<MapPbx>('buildSettings')
        ?.find<MapEntryPbx>('PRODUCT_BUNDLE_IDENTIFIER')
        ?.value
        .toString();
    final candidate = _unquote(raw);
    if (candidate != null && !candidate.contains(r'$(')) {
      bundleId = candidate;
      break;
    }
  }

  return (targetName: targetName, bundleId: bundleId);
}

/// Strips surrounding double quotes from a pbxproj scalar, if present.
String? _unquote(String? value) {
  if (value == null) return null;
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value.substring(1, value.length - 1);
  }
  return value;
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
