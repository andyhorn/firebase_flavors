import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'src/get_pubspec_version.dart';
import 'src/init.dart';
import 'src/logger.dart';
import 'src/models/arg_parser.dart';
import 'src/models/flavor_config.dart';
import 'src/models/global_config.dart';

void printUsage(ArgParser argParser) {
  print('Usage: dart firebase_flavors.dart <flags> [arguments]');
  print(argParser.usage);
}

void main(List<String> arguments) async {
  final argParser = getArgParser();

  try {
    final results = argParser.parse(arguments);
    final verbose = results.flag('verbose');

    // Initialize logger with verbosity
    initLogger(verbose: verbose);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }

    if (results.flag('version')) {
      print('firebase_flavors version: ${getPubspecVersion()}');
      return;
    }

    logDebug('Arguments: ${results.arguments}');

    if (results.rest.isEmpty) {
      logError('No arguments provided');
      printUsage(argParser);
      return;
    }

    final command = results.rest.first.toLowerCase();

    if (command == 'init') {
      logInfo('Initializing firebase_flavors configuration...');
      await init(force: results.flag('force'));
      return;
    }

    if (command == 'configure') {
      if (results.rest.length > 2) {
        logError('Invalid number of arguments');
        printUsage(argParser);
        return;
      }

      final flavors = <String>[];

      if (results.rest.length > 1) {
        flavors.addAll(results.rest[1].split(',').map((e) => e.trim()));
      }

      logInfo('Configuring Firebase flavors...');
      await _configure(flavors);
      return;
    }

    logError('Unknown command: $command');
    printUsage(argParser);
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    logError('Invalid arguments: ${e.message}');
    print('');
    printUsage(argParser);
  } catch (e, stackTrace) {
    logError('Unexpected error occurred', e, stackTrace);
    exit(1);
  }
}

Future<void> _configure(List<String> flavors) async {
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
    '--yes',
  ];

  logDebug('Running flutterfire with args: ${args.join(' ')}');
  logInfo('Project: ${flavorConfig.firebaseProjectId}');
  logDebug(
    'Android package: ${config.baseBundleId}${flavorConfig.androidPackageSuffix}',
  );
  logDebug('Dart options out: ${flavorConfig.dartOptionsOut}');

  final result = await Process.run('flutterfire', args);

  if (result.exitCode != 0) {
    logError('flutterfire configure failed for flavor "${flavorConfig.name}"');
    logError('Exit code: ${result.exitCode}');
    if (result.stderr.toString().isNotEmpty) {
      logError('Error output: ${result.stderr}');
    }
    if (result.stdout.toString().isNotEmpty) {
      logDebug('Output: ${result.stdout}');
    }
    exit(result.exitCode);
  }

  logDebug('flutterfire output: ${result.stdout}');
}
