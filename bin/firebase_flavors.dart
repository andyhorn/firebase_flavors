import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'src/get_pubspec_version.dart';
import 'src/init.dart';
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

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }

    if (results.flag('version')) {
      print('firebase_flavors version: ${getPubspecVersion()}');
      return;
    }

    if (verbose) {
      print('[VERBOSE] Arguments: ${results.arguments}');
    }

    if (results.rest.isEmpty) {
      print('No arguments provided');
      printUsage(argParser);
      return;
    }

    if (results.rest.first.toLowerCase() == 'init') {
      await init(force: results.flag('force'));
      return;
    }

    if (results.rest.first.toLowerCase() == 'configure') {
      if (results.rest.length > 2) {
        print('Invalid number of arguments');
        printUsage(argParser);
        return;
      }

      final flavors = results.rest.length == 1
          ? const <String>[]
          : results.rest[1].split(',').map((e) => e.trim()).toList();

      await _configure(flavors);
      return;
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}

Future<void> _configure(List<String> flavors) async {
  final config = _readConfig();

  if (flavors.isEmpty) {
    flavors.addAll(config.flavors.keys);
  }

  for (final flavor in flavors) {
    if (!config.flavors.containsKey(flavor)) {
      print('Flavor $flavor not found');
      continue;
    }

    await _configureFlavor(config, config.flavors[flavor]!);
  }
}

GlobalConfig _readConfig() {
  final file = File('firebase_flavors.yaml');
  final content = file.readAsStringSync();
  final yaml = loadYaml(content) as Map<String, dynamic>;

  return GlobalConfig.fromMap(yaml);
}

Future<void> _configureFlavor(
  GlobalConfig config,
  FlavorConfig flavorConfig,
) async {
  Process.run('flutterfire', [
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
  ]);
}
