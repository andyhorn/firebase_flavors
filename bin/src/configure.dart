import 'dart:io';

import 'ios_run_script.dart';
import 'logger.dart';
import 'prerequisites.dart';
import 'services/firebase_service.dart';
import 'utils/config_reader.dart';

Future<void> configure(
  List<String> flavors, {
  bool skipFirebase = false,
  bool skipXcode = false,
  required String configPath,
}) async {
  logInfo('Reading configuration from $configPath...');
  final config = ConfigReader.readConfig(configPath);
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
      logInfo('Available flavors: ${config.flavors.keys.join(', ')}');
      logInfo('Add this flavor to $configPath or check for typos.');
      return false;
    }

    return true;
  });

  // Check if any flavors have an iOS platform
  final configuredIos = flavorsToRun.any((flavor) {
    final names = ConfigReader.normalizePlatforms(config.flavors[flavor]!.platforms);
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
    final firebaseService = FirebaseService();
    for (final flavor in flavorsToRun) {
      final flavorConfig = config.flavors[flavor]!;
      final platformNames = ConfigReader.normalizePlatforms(flavorConfig.platforms);

      logInfo('Configuring flavor: $flavor');
      await firebaseService.configureFlavor(config, flavorConfig, platformNames);
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
