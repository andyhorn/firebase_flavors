import 'exceptions.dart';
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

  final selectedFlavors = flavors.isEmpty
      ? config.flavors.keys.toList()
      : List.of(flavors);
  if (flavors.isEmpty) {
    logInfo(
      'No flavors specified, configuring all flavors: ${selectedFlavors.join(', ')}',
    );
  } else {
    logInfo('Configuring flavors: ${selectedFlavors.join(', ')}');
  }

  // Filter invalid flavors and log warnings once.
  final flavorsToRun = <String>[];
  for (final flavor in selectedFlavors) {
    if (config.flavors[flavor] == null) {
      logWarning('Flavor "$flavor" not found in configuration. Skipping.');
      logInfo('Available flavors: ${config.flavors.keys.join(', ')}');
      logInfo('Add this flavor to $configPath or check for typos.');
      continue;
    }
    flavorsToRun.add(flavor);
  }

  // Validate that all flavors to be configured have a Firebase project ID.
  // Skipped when --skip-firebase is set (Xcode-only setup doesn't need IDs).
  if (!skipFirebase) {
    final unset = flavorsToRun
        .where((f) => !config.flavors[f]!.hasFirebaseProjectId)
        .toList();
    if (unset.isNotEmpty) {
      logInfo('Run: firebase_flavors set-project-ids');
      logInfo('Or set firebaseProjectId in $configPath manually.');
      throw FirebaseFlavorsException(
        'Cannot configure: ${unset.length} flavor(s) have no '
        'Firebase project ID set: ${unset.join(', ')}',
      );
    }
  }

  // Check if any flavors have an iOS platform
  final configuredIos = flavorsToRun.any((flavor) {
    final names = ConfigReader.normalizePlatforms(
      config.flavors[flavor]!.platforms,
    );
    return names.isEmpty || names.contains('ios');
  });

  // Check prerequisites before proceeding
  final needsFirebase = !skipFirebase;
  final needsIosScript = !skipXcode && configuredIos;

  if (needsFirebase || needsIosScript) {
    final prerequisitesMet = await checkPrerequisites(needsIos: needsIosScript);
    if (!prerequisitesMet) {
      throw FirebaseFlavorsException(
        'Prerequisites check failed. Please install missing tools and try again.',
      );
    }
  }

  // Run Firebase configuration unless skip-firebase is specified
  if (!skipFirebase) {
    final firebaseService = FirebaseService();
    for (final flavor in flavorsToRun) {
      final flavorConfig = config.flavors[flavor]!;
      final platformNames = ConfigReader.normalizePlatforms(
        flavorConfig.platforms,
      );

      logInfo('Configuring flavor: $flavor');
      await firebaseService.configureFlavor(
        config,
        flavorConfig,
        platformNames,
      );
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
