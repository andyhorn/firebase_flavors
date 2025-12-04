import 'dart:io';

import 'package:args/args.dart';

import 'src/configure.dart';
import 'src/get_pubspec_version.dart';
import 'src/init.dart';
import 'src/list.dart';
import 'src/logger.dart';
import 'src/models/arg_parser.dart';

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
      logError('No command provided');
      logInfo('Available commands: init, configure, list');
      logInfo('Use --help for more information.');
      printUsage(argParser);
      return;
    }

    final command = results.rest.first.toLowerCase();
    final configPath = results['config'] as String;

    if (command == 'init') {
      logInfo('Initializing firebase_flavors configuration...');
      await init(force: results.flag('force'), configPath: configPath);
      return;
    }

    if (command == 'list') {
      await listFlavors(configPath: configPath);
      return;
    }

    if (command == 'configure') {
      if (results.rest.length > 2) {
        logError('Too many arguments for configure command');
        logInfo('Usage: firebase_flavors configure [flavor1,flavor2,...]');
        logInfo('Example: firebase_flavors configure dev,staging');
        printUsage(argParser);
        return;
      }

      final skipFirebase = results.flag('skip-firebase');
      final skipXcode = results.flag('skip-xcode');

      final flavors = <String>[];

      if (results.rest.length > 1) {
        flavors.addAll(results.rest[1].split(',').map((e) => e.trim()));
      }

      logInfo('Configuring Firebase flavors...');
      await configure(
        flavors,
        skipFirebase: skipFirebase,
        skipXcode: skipXcode,
        configPath: configPath,
      );
      return;
    }

    logError('Unknown command: $command');
    logInfo('Available commands: init, configure, list');
    logInfo('Use --help for more information.');
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
