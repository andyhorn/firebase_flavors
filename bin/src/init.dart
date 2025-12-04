import 'dart:io';

import 'logger.dart';

/// Holds all detected values from Android or iOS project files.
class _DetectionResult {
  _DetectionResult({
    this.baseBundleId,
    this.flavors = const [],
    this.flavorSuffixes = const {},
    this.appName,
    this.iosTarget,
    this.iosBuildConfigs,
  });

  final String? baseBundleId;
  final List<String> flavors;
  final Map<String, String> flavorSuffixes; // flavor -> suffix
  final String? appName;
  final String? iosTarget;
  final List<String>? iosBuildConfigs;
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
        iosBuildConfigs: iosResult.iosBuildConfigs,
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
  final yamlContent = _generateYamlContent(
    baseBundleId: baseBundleId,
    appName: appName,
    flavors: flavors,
    flavorSuffixes: flavorSuffixes,
    iosTarget: result?.iosTarget,
    iosBuildConfigs: result?.iosBuildConfigs,
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
    final baseBundleId = _extractApplicationId(content);
    final flavorData = _extractProductFlavors(content, isKts);
    final appName = _extractAppNameFromGradle(content);

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

/// Extracts the base applicationId from gradle content.
/// Supports both `applicationId` and `namespace` properties.
String? _extractApplicationId(String gradleContent) {
  // Try applicationId first (in defaultConfig or android block)
  final applicationIdPattern =
      '(?:defaultConfig|android)\\s*\\{[\\s\\S]*?applicationId\\s*[=:]\\s*["\']([^\'"]+)["\']';
  final applicationIdRegex = RegExp(applicationIdPattern, multiLine: true);
  final applicationIdMatch = applicationIdRegex.firstMatch(gradleContent);
  if (applicationIdMatch != null) {
    return applicationIdMatch.group(1);
  }

  // Fallback to namespace (for newer Gradle files)
  final namespacePattern = 'namespace\\s*[=:]\\s*["\']([^\'"]+)["\']';
  final namespaceRegex = RegExp(namespacePattern, multiLine: true);
  final namespaceMatch = namespaceRegex.firstMatch(gradleContent);
  if (namespaceMatch != null) {
    return namespaceMatch.group(1);
  }

  return null;
}

/// Extracts product flavors and their applicationIdSuffix values.
/// Returns a map of flavor name -> suffix (empty string if no suffix).
Map<String, String> _extractProductFlavors(String gradleContent, bool isKts) {
  final flavors = <String, String>{};

  // Find the productFlavors block
  final flavorsBlockPattern = r'productFlavors\s*\{((?:[^{}]|\{[^{}]*\})*)\}';
  final flavorsBlockRegex = RegExp(flavorsBlockPattern);
  final flavorsBlockMatch = flavorsBlockRegex.firstMatch(gradleContent);
  if (flavorsBlockMatch == null) {
    return flavors;
  }

  final flavorsBlockBody = flavorsBlockMatch.group(1)!;

  if (isKts) {
    // Kotlin DSL: create("flavorName") { ... }
    final createFlavorPattern =
        'create\\s*\\(\\s*["\']([A-Za-z0-9_]+)["\']\\s*\\)\\s*\\{([^{}]*(?:\\{[^{}]*\\}[^{}]*)*)\\}';
    final createFlavorRegex = RegExp(createFlavorPattern);

    for (final match in createFlavorRegex.allMatches(flavorsBlockBody)) {
      final flavorName = match.group(1)!;
      final flavorBody = match.group(2) ?? '';

      // Extract applicationIdSuffix from flavor body
      final suffixPattern =
          'applicationIdSuffix\\s*[=:]\\s*["\']([^\'"]*)["\']';
      final suffixRegex = RegExp(suffixPattern);
      final suffixMatch = suffixRegex.firstMatch(flavorBody);
      var suffix = suffixMatch?.group(1) ?? '';

      // Strip any leading dot when parsing (will be normalized later)
      if (suffix.isNotEmpty && suffix.startsWith('.')) {
        suffix = suffix.substring(1);
      }

      flavors[flavorName] = suffix.isEmpty ? '' : suffix;
    }
  } else {
    // Groovy DSL: flavorName { ... }
    final flavorNamePattern =
        r'\b([A-Za-z0-9_]+)\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}';
    final flavorNameRegex = RegExp(flavorNamePattern);

    for (final match in flavorNameRegex.allMatches(flavorsBlockBody)) {
      final flavorName = match.group(1)!;
      final flavorBody = match.group(2) ?? '';

      // Extract applicationIdSuffix from flavor body
      final suffixPattern =
          'applicationIdSuffix\\s*[=:]\\s*["\']([^\'"]*)["\']';
      final suffixRegex = RegExp(suffixPattern);
      final suffixMatch = suffixRegex.firstMatch(flavorBody);
      var suffix = suffixMatch?.group(1) ?? '';

      // Strip any leading dot when parsing (will be normalized later)
      if (suffix.isNotEmpty && suffix.startsWith('.')) {
        suffix = suffix.substring(1);
      }

      flavors[flavorName] = suffix.isEmpty ? '' : suffix;
    }
  }

  return flavors;
}

/// Extracts app name from manifestPlaceholders in gradle content.
String? _extractAppNameFromGradle(String gradleContent) {
  // Look for manifestPlaceholders["appName"] = "App Name"
  final appNamePattern =
      'manifestPlaceholders\\s*\\["appName"\\]\\s*[=:]\\s*["\']([^\'"]+)["\']';
  final appNameRegex = RegExp(appNamePattern, multiLine: true);
  final appNameMatch = appNameRegex.firstMatch(gradleContent);
  if (appNameMatch != null) {
    return appNameMatch.group(1);
  }

  return null;
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
  List<String>? iosBuildConfigs;

  if (pbxprojFile != null && pbxprojFile.existsSync()) {
    logDebug('Found project.pbxproj: ${pbxprojFile.path}');
    try {
      baseBundleId ??= _extractBundleIdFromPbxproj(pbxprojFile);
      iosBuildConfigs = _extractBuildConfigsFromPbxproj(pbxprojFile);
      iosTarget = _extractTargetFromPbxproj(pbxprojFile);
      if (baseBundleId != null) {
        logDebug('Extracted bundle ID from project.pbxproj: $baseBundleId');
      }
      if (iosBuildConfigs.isNotEmpty) {
        logDebug('Extracted build configs: ${iosBuildConfigs.join(', ')}');
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
  if (baseBundleId != null ||
      appName != null ||
      (iosBuildConfigs != null && iosBuildConfigs.isNotEmpty)) {
    // Try to infer flavors from build configurations
    final flavors = _inferFlavorsFromBuildConfigs(iosBuildConfigs);

    return _DetectionResult(
      baseBundleId: baseBundleId,
      flavors: flavors,
      appName: appName,
      iosTarget: iosTarget ?? 'Runner',
      iosBuildConfigs: iosBuildConfigs,
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

/// Extracts build configurations from project.pbxproj file.
List<String> _extractBuildConfigsFromPbxproj(File pbxprojFile) {
  final content = pbxprojFile.readAsStringSync();
  final configs = <String>[];

  // Look for XCBuildConfiguration sections
  // Format: name = Debug; or name = Release-production;
  final configNamePattern = r'name\s*=\s*([A-Za-z0-9_-]+)\s*;';
  final configNameRegex = RegExp(configNamePattern, multiLine: true);

  final matches = configNameRegex.allMatches(content);
  for (final match in matches) {
    final configName = match.group(1)!;
    // Filter out common base configs and keep flavor-specific ones
    if (!configName.startsWith('Debug') &&
        !configName.startsWith('Release') &&
        !configName.startsWith('Profile')) {
      continue;
    }
    if (!configs.contains(configName)) {
      configs.add(configName);
    }
  }

  return configs;
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

/// Infers flavor names from iOS build configuration names.
/// E.g., "Debug-production", "Release-staging" -> ["production", "staging"]
List<String> _inferFlavorsFromBuildConfigs(List<String>? buildConfigs) {
  if (buildConfigs == null || buildConfigs.isEmpty) {
    return [];
  }

  final flavors = <String>{};
  for (final config in buildConfigs) {
    // Extract flavor from config names like "Debug-production", "Release-staging"
    final parts = config.split('-');
    if (parts.length > 1) {
      // Skip the build type (Debug/Release/Profile) and get the flavor
      final flavor = parts.sublist(1).join('-');
      if (flavor.isNotEmpty) {
        flavors.add(flavor);
      }
    }
  }

  return flavors.toList()..sort();
}

/// Generates the YAML configuration file content.
String _generateYamlContent({
  required String baseBundleId,
  required String appName,
  required List<String> flavors,
  required Map<String, String> flavorSuffixes,
  String? iosTarget,
  List<String>? iosBuildConfigs,
}) {
  final buffer = StringBuffer();

  buffer.writeln(
    '# Firebase flavor configuration generated by firebase_flavor_tool init',
  );
  buffer.writeln('# Review and edit as needed.');
  buffer.writeln('');
  buffer.writeln('appName: $appName');
  buffer.writeln('baseBundleId: $baseBundleId');
  buffer.writeln('');
  buffer.writeln('android:');
  buffer.writeln('  srcBase: android/app/src');
  buffer.writeln('');
  buffer.writeln('ios:');
  buffer.writeln('  xcodeprojPath: ios/${iosTarget ?? 'Runner'}.xcodeproj');
  buffer.writeln('  target: ${iosTarget ?? 'Runner'}');
  buffer.writeln('  configBase: ios/${iosTarget ?? 'Runner'}/Config');
  buffer.writeln('');
  buffer.writeln('flavors:');

  for (final flavor in flavors) {
    // Use detected suffix if available, otherwise infer from flavor name
    String suffix;
    if (flavorSuffixes.containsKey(flavor)) {
      suffix = flavorSuffixes[flavor]!;
    } else {
      final isProdLike =
          flavor.toLowerCase() == 'prod' ||
          flavor.toLowerCase() == 'production';
      suffix = isProdLike ? '' : flavor;
    }

    final optionsOut = 'lib/firebase_options_$flavor.dart';
    final androidSrcDir = flavor;
    final iosConfigDir = flavor;

    buffer.writeln('  $flavor:');
    buffer.writeln(
      '    firebaseProjectId: your-firebase-project-id-for-$flavor',
    );
    buffer.writeln('    androidPackageSuffix: $suffix');
    buffer.writeln('    dartOptionsOut: $optionsOut');
    buffer.writeln('    androidSrcDir: $androidSrcDir');
    buffer.writeln('    iosConfigDir: $iosConfigDir');
    buffer.writeln('    # Optional: override iOS bundle ID for this flavor.');
    buffer.writeln('    # iosBundleId: com.example.app.$flavor');

    // Use detected build configs if available, otherwise generate defaults
    buffer.writeln('    iosBuildConfigs:');
    if (iosBuildConfigs != null && iosBuildConfigs.isNotEmpty) {
      // Filter configs for this flavor
      final flavorConfigs = iosBuildConfigs
          .where(
            (config) => config.toLowerCase().contains(flavor.toLowerCase()),
          )
          .toList();
      if (flavorConfigs.isNotEmpty) {
        for (final config in flavorConfigs) {
          buffer.writeln('      - $config');
        }
      } else {
        // Fallback to default pattern
        buffer.writeln('      - Debug-$flavor');
        buffer.writeln('      - Release-$flavor');
        buffer.writeln('      - Profile-$flavor');
      }
    } else {
      // Default pattern
      buffer.writeln('      - Debug-$flavor');
      buffer.writeln('      - Release-$flavor');
      buffer.writeln('      - Profile-$flavor');
    }
    buffer.writeln('');
  }

  return buffer.toString();
}
