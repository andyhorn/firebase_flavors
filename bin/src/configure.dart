import 'dart:io';

import 'package:yaml/yaml.dart';

import 'ios_run_script.dart';
import 'logger.dart';
import 'models/flavor_config.dart';
import 'models/global_config.dart';
import 'prerequisites.dart';

Future<void> configure(
  List<String> flavors, {
  bool skipFirebase = false,
  bool skipXcode = false,
}) async {
  logInfo('Reading configuration from firebase_flavors.yaml...');
  final config = _readConfig();
  logSuccess('Configuration loaded successfully');

  if (flavors.isEmpty) {
    logInfo(
      'No flavors specified, configuring all flavors: ${config.flavors.keys.join(', ')}',
    );
    flavors.addAll(config.flavors.keys);
  } else {
    logInfo('Configuring flavors: ${flavors.join(', ')}');
  }

  // Filter invalid flavors and log warnings
  final flavorsToRun = flavors.where((flavor) {
    if (config.flavors[flavor] == null) {
      logWarning('Flavor "$flavor" not found in configuration. Skipping.');
      return false;
    }

    return true;
  });

  // Check if any flavors have an iOS platform
  final configuredIos = flavorsToRun.any((flavor) {
    final names = _normalizePlatforms(config.flavors[flavor]!.platforms);
    return names.isEmpty || names.contains('ios');
  });

  // Check prerequisites before proceeding
  final needsFirebase = !skipFirebase;
  final needsIosScript = !skipXcode && configuredIos;

  if (needsFirebase || needsIosScript) {
    final prerequisitesMet = await checkPrerequisites(needsIos: needsIosScript);
    if (!prerequisitesMet) {
      logError(
        'Prerequisites check failed. Please install missing tools and try again.',
      );
      exit(1);
    }
  }

  // Run Firebase configuration unless skip-firebase is specified
  if (!skipFirebase) {
    for (final flavor in flavorsToRun) {
      final flavorConfig = config.flavors[flavor]!;
      final platformNames = _normalizePlatforms(flavorConfig.platforms);

      logInfo('Configuring flavor: $flavor');
      await _configureFlavor(config, flavorConfig, platformNames);
      logSuccess('Flavor "$flavor" configured successfully');
    }
  } else {
    logDebug('Skipping Firebase configuration (--skip-firebase flag set).');
  }

  // Run Xcode script setup unless skip-xcode is specified
  if (!skipXcode) {
    if (configuredIos) {
      await ensureIosGoogleServicesRunScript(config);
    } else {
      logDebug('No iOS flavors selected, skipping Xcode run script setup.');
    }
  } else {
    logDebug('Skipping Xcode run script setup (--skip-xcode flag set).');
  }

  logSuccess('All flavors configured');
}

GlobalConfig _readConfig() {
  final file = File('firebase_flavors.yaml');

  if (!file.existsSync()) {
    logError('Configuration file firebase_flavors.yaml not found.');
    logInfo('Run "firebase_flavors init" to create a configuration file.');
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
    logError('Failed to parse configuration file', e, stackTrace);
    exit(1);
  }
}

Future<void> _configureFlavor(
  GlobalConfig config,
  FlavorConfig flavorConfig,
  List<String> platformNames,
) async {
  final android = platformNames.isEmpty || platformNames.contains('android');
  final ios = platformNames.isEmpty || platformNames.contains('ios');

  final args = [
    'configure',
    '--project=${flavorConfig.firebaseProjectId}',
    '--out=${flavorConfig.dartOptionsOut}',
    if (platformNames.isNotEmpty) ...['--platforms=${platformNames.join(',')}'],
    if (android) ...[
      '--android-package-name=${config.baseBundleId}${flavorConfig.androidPackageSuffix}',
      '--android-out=${config.androidSrcBase}/${flavorConfig.androidSrcDir}/google-services.json',
    ],
    if (ios) ...[
      '--ios-bundle-id=${flavorConfig.iosBundleId ?? config.baseBundleId}',
      '--ios-out=${config.iosConfigBase}/${flavorConfig.iosConfigDir}/GoogleService-Info.plist',
      '--ios-build-config=Debug-${flavorConfig.name}',
    ],
    '--yes',
  ];

  logDebug('Running flutterfire with args: ${args.join(' ')}');
  logInfo('Project: ${flavorConfig.firebaseProjectId}');
  if (android) {
    logDebug(
      'Android package: ${config.baseBundleId}${flavorConfig.androidPackageSuffix}',
    );
  }
  if (ios) {
    final iosBundleId = flavorConfig.iosBundleId ?? config.baseBundleId;
    logDebug('iOS bundle ID: $iosBundleId');
  }
  logDebug('Dart options out: ${flavorConfig.dartOptionsOut}');

  Process process;
  try {
    process = await Process.start(
      'flutterfire',
      args,
      mode: ProcessStartMode.inheritStdio,
    );
  } on ProcessException catch (e, stackTrace) {
    logError(
      '\nFailed to start flutterfire. Ensure it is installed and on your PATH.',
      e,
      stackTrace,
    );
    exit(1);
  }

  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    logError('flutterfire configure failed for flavor "${flavorConfig.name}"');
    logError('Exit code: $exitCode');
    exit(exitCode);
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
