import 'dart:io';

import 'src/exceptions.dart';
import 'src/logger.dart';
import 'src/models/arg_parser.dart';
import 'src/models/command_handler.dart';

void main(List<String> arguments) async {
  final commandParser = CommandParser.create();
  final commandHandler = CommandHandler(commandParser);

  try {
    final results = commandParser.parse(arguments);
    await commandHandler.execute(results);
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    logError('Invalid arguments: ${e.message}');
    print('');
    print('Usage: dart firebase_flavors.dart <flags> [arguments]');
    print(commandParser.parser.usage);
    exit(1);
  } on FirebaseFlavorsException catch (e) {
    logError(e.message);
    exit(e.exitCode);
  } catch (e, stackTrace) {
    logError('Unexpected error occurred', e, stackTrace);
    exit(1);
  }
}
