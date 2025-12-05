import 'logger.dart';
import 'utils/config_reader.dart';

/// Lists all configured flavors and their details.
Future<void> listFlavors({required String configPath}) async {
  logInfo('Reading configuration from $configPath...');
  final config = ConfigReader.readConfig(configPath);
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
    final platformNames = ConfigReader.normalizePlatforms(
      flavorConfig.platforms,
    );
    final platforms = platformNames.isEmpty
        ? 'all platforms'
        : platformNames.join(', ');

    print('  $flavor:');
    print('    Firebase Project: ${flavorConfig.firebaseProjectId}');
    print('    Platforms: $platforms');

    // Android details
    if (platformNames.isEmpty || platformNames.contains('android')) {
      final androidPackage = flavorConfig.getAndroidBundleId(config.baseBundleId);
      final androidPath =
          '${config.androidSrcBase}/${flavorConfig.androidSrcDir}/google-services.json';
      print('    Android:');
      print('      Package: $androidPackage');
      print('      Config: $androidPath');
    }

    // iOS details
    if (platformNames.isEmpty || platformNames.contains('ios')) {
      final iosBundleId = flavorConfig.getIosBundleId(config.baseBundleId);
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
