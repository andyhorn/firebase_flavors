import 'dart:io';

import 'package:yaml/yaml.dart';

import 'logger.dart';
import 'models/flavor_config.dart';
import 'models/global_config.dart';

Future<void> configure(List<String> flavors) async {
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

  for (final flavor in flavors) {
    if (!config.flavors.containsKey(flavor)) {
      logWarning('Flavor "$flavor" not found in configuration. Skipping.');
      continue;
    }

    logInfo('Configuring flavor: $flavor');
    await _configureFlavor(config, config.flavors[flavor]!);
    logSuccess('Flavor "$flavor" configured successfully');
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
) async {
  final args = [
    'configure',
    '--project=${flavorConfig.firebaseProjectId}',
    '--out=${flavorConfig.dartOptionsOut}',
    if (flavorConfig.platforms?.isNotEmpty ?? false) ...[
      '--platforms=${flavorConfig.platforms}',
    ],
    '--android-package-name=${config.baseBundleId}${flavorConfig.androidPackageSuffix}',
    '--android-out=${flavorConfig.androidSrcDir}/google-services.json',
    '--ios-bundle-id=${config.baseBundleId}',
    '--ios-out=${flavorConfig.iosConfigDir}/GoogleService-Info.plist',
    '--ios-build-config=Debug-${flavorConfig.name}',
    '--yes',
  ];

  logDebug('Running flutterfire with args: ${args.join(' ')}');
  logInfo('Project: ${flavorConfig.firebaseProjectId}');
  logDebug(
    'Android package: ${config.baseBundleId}${flavorConfig.androidPackageSuffix}',
  );
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
