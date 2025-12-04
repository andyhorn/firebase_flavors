import 'dart:io';

import 'package:yaml/yaml.dart';

import 'logger.dart';
import 'models/global_config.dart';

/// Lists all configured flavors and their details.
Future<void> listFlavors({required String configPath}) async {
  logInfo('Reading configuration from $configPath...');
  final config = _readConfig(configPath);
  logSuccess('Configuration loaded successfully');
  print('');

  // Display global configuration
  print('App Configuration:');
  print('  App Name: ${config.appName}');
  print('  Base Bundle ID: ${config.baseBundleId}');
  print('');

  // Display platform paths
  print('Platform Paths:');
  print('  Android Source Base: ${config.androidSrcBase}');
  print('  iOS Xcode Project: ${config.iosXcodeprojPath}');
  print('  iOS Target: ${config.iosTarget}');
  print('  iOS Config Base: ${config.iosConfigBase}');
  print('');

  // Display flavors
  if (config.flavors.isEmpty) {
    logWarning('No flavors configured.');
    logInfo('Run "firebase_flavors init" to create flavors.');
    return;
  }

  print('Configured Flavors (${config.flavors.length}):');
  print('');

  for (final entry in config.flavors.entries) {
    final flavor = entry.key;
    final flavorConfig = entry.value;
    final platformNames = _normalizePlatforms(flavorConfig.platforms);
    final platforms = platformNames.isEmpty
        ? 'all platforms'
        : platformNames.join(', ');

    print('  $flavor:');
    print('    Firebase Project: ${flavorConfig.firebaseProjectId}');
    print('    Platforms: $platforms');

    // Android details
    if (platformNames.isEmpty || platformNames.contains('android')) {
      final androidPackage =
          config.baseBundleId + (flavorConfig.androidPackageSuffix ?? '');
      final androidPath =
          '${config.androidSrcBase}/${flavorConfig.androidSrcDir}/google-services.json';
      print('    Android:');
      print('      Package: $androidPackage');
      print('      Config: $androidPath');
    }

    // iOS details
    if (platformNames.isEmpty || platformNames.contains('ios')) {
      final iosBundleId = flavorConfig.iosBundleId ?? config.baseBundleId;
      final iosPath =
          '${config.iosConfigBase}/${flavorConfig.iosConfigDir}/GoogleService-Info.plist';
      print('    iOS:');
      print('      Bundle ID: $iosBundleId');
      print('      Config: $iosPath');
    }

    // Dart options
    print('    Dart Options: ${flavorConfig.dartOptionsOut}');
    print('');
  }
}

GlobalConfig _readConfig(String configPath) {
  final file = File(configPath);

  if (!file.existsSync()) {
    final absolutePath = file.absolute.path;
    logError('Configuration file $configPath not found.');
    logInfo('Expected location: $absolutePath');
    logInfo('Run "firebase_flavors init" to create a configuration file.');
    logInfo(
      'Or ensure you are running this command from your Flutter project root directory.',
    );
    exit(1);
  }

  logDebug('Reading configuration file: ${file.path}');
  final content = file.readAsStringSync();
  final yaml = loadYaml(content) as YamlMap;

  try {
    final config = GlobalConfig.fromYaml(yaml);
    logDebug(
      'Configuration parsed successfully. Found ${config.flavors.length} flavor(s)',
    );
    return config;
  } catch (e, stackTrace) {
    logError(
      'Failed to parse configuration file: ${file.absolute.path}',
      e,
      stackTrace,
    );
    if (e is ArgumentError) {
      logInfo('Configuration error: ${e.message}');
      logInfo('Please check your $configPath file for syntax errors.');
    } else if (e.toString().contains('YAML')) {
      logInfo(
        'YAML syntax error detected. Please verify your configuration file format.',
      );
      logInfo(
        'Common issues: missing quotes, incorrect indentation, or invalid characters.',
      );
    }
    exit(1);
  }
}

List<String> _normalizePlatforms(String? platforms) {
  if (platforms == null || platforms.isEmpty) {
    return <String>[];
  }

  return platforms
      .split(',')
      .map((p) => p.toLowerCase().trim())
      .where((p) => p.isNotEmpty)
      .toList();
}
