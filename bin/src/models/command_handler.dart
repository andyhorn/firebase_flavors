import 'package:args/args.dart';

import '../configure.dart';
import '../get_pubspec_version.dart';
import '../init.dart';
import '../list.dart';
import '../logger.dart';
import '../set_project_ids.dart';
import 'arg_parser.dart';

/// Handles command execution based on parsed arguments.
class CommandHandler {
  final CommandParser _commandParser;

  CommandHandler(this._commandParser);

  /// Executes the command based on the parsed results.
  Future<void> execute(ArgResults results) async {
    final verbose = results.flag('verbose');

    // Initialize logger with verbosity
    initLogger(verbose: verbose);

    // Handle global flags that don't require a command
    if (results.flag('help')) {
      _printUsage(_commandParser.parser);
      return;
    }

    if (results.flag('version')) {
      print('firebase_flavors version: ${getPubspecVersion()}');
      return;
    }

    // Get command from parsed results
    final command = results.command;
    if (command == null) {
      logError('No command provided');
      logInfo('Available commands: init, configure, list, set-project-ids');
      logInfo('Use --help for more information.');
      _printUsage(_commandParser.parser);
      return;
    }

    final commandName = command.name;
    final commandResults = command;
    final configPath = results['config'] as String;

    // Execute command
    switch (commandName) {
      case 'init':
        await _handleInit(commandResults, configPath);
        break;
      case 'list':
        await _handleList(configPath);
        break;
      case 'configure':
        await _handleConfigure(commandResults, configPath);
        break;
      case 'set-project-ids':
        await _handleSetProjectIds(commandResults, configPath);
        break;
      default:
        logError('Unknown command: $commandName');
        logInfo('Available commands: init, configure, list, set-project-ids');
        logInfo('Use --help for more information.');
        _printUsage(_commandParser.parser);
    }
  }

  Future<void> _handleInit(ArgResults commandResults, String configPath) async {
    logInfo('Initializing firebase_flavors configuration...');
    await init(force: commandResults['force'] as bool, configPath: configPath);
  }

  Future<void> _handleList(String configPath) async {
    await listFlavors(configPath: configPath);
  }

  Future<void> _handleConfigure(
    ArgResults commandResults,
    String configPath,
  ) async {
    if (commandResults.rest.length > 1) {
      logError('Too many arguments for configure command');
      logInfo('Usage: firebase_flavors configure [flavor1,flavor2,...]');
      logInfo('Example: firebase_flavors configure dev,staging');
      final commandParser = _commandParser.parser.commands['configure'];
      if (commandParser != null) {
        _printUsage(commandParser);
      }
      return;
    }

    final skipFirebase = commandResults['skip-firebase'] as bool;
    final skipXcode = commandResults['skip-xcode'] as bool;

    final flavors = <String>[];

    if (commandResults.rest.isNotEmpty) {
      flavors.addAll(commandResults.rest.first.split(',').map((e) => e.trim()));
    }

    logInfo('Configuring Firebase flavors...');
    await configure(
      flavors,
      skipFirebase: skipFirebase,
      skipXcode: skipXcode,
      configPath: configPath,
    );
  }

  Future<void> _handleSetProjectIds(
    ArgResults commandResults,
    String configPath,
  ) async {
    final fromFiles = commandResults['from-files'] as bool;
    final fromFirebase = commandResults['from-firebase'] as bool;
    final interactive = commandResults['interactive'] as bool;
    final projectIds = commandResults['project-ids'] as String?;

    logInfo('Setting Firebase project IDs...');
    await setProjectIds(
      configPath: configPath,
      fromFiles: fromFiles,
      fromFirebase: fromFirebase,
      interactive: interactive,
      projectIds: projectIds,
    );
  }

  void _printUsage(ArgParser argParser) {
    print('Usage: dart firebase_flavors.dart <flags> [arguments]');
    print(argParser.usage);
  }
}
