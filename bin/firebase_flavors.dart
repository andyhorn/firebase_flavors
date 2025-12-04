import 'dart:io';

import 'package:args/args.dart';

import 'src/configure.dart';
import 'src/get_pubspec_version.dart';
import 'src/init.dart';
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
      await configure(flavors);
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
