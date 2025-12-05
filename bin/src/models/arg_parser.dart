import 'package:args/args.dart';

/// Manages argument parsing for the firebase_flavors CLI tool.
/// Encapsulates the creation and configuration of the main ArgParser with commands.
class CommandParser {
  final ArgParser _parser;

  CommandParser._(this._parser);

  /// Creates a new CommandParser instance with all commands registered.
  factory CommandParser.create() {
    final parser = ArgParser();
    _applyBaseFlags(parser);

    // Create command parsers (without base flags, as they inherit from parent)
    final initParser = ArgParser()
      ..addFlag('force', help: 'Overwrite existing files.');

    final listParser = ArgParser();

    final configureParser = ArgParser()
      ..addFlag(
        'skip-firebase',
        negatable: false,
        help: 'Skip Firebase configuration.',
      )
      ..addFlag(
        'skip-xcode',
        negatable: false,
        help: 'Skip Xcode script setup.',
      );

    final setProjectIdsParser = ArgParser()
      ..addFlag(
        'from-files',
        negatable: false,
        help: 'Auto-detect project IDs from existing config files.',
      )
      ..addFlag(
        'from-firebase',
        negatable: false,
        help: 'Interactive selection from Firebase CLI projects list.',
      )
      ..addFlag(
        'interactive',
        negatable: false,
        help: 'Prompt for project IDs interactively.',
      )
      ..addOption(
        'project-ids',
        help:
            'Comma-separated list of flavor:project-id pairs (e.g., dev:project-id-1,prod:project-id-2).',
      );

    // Register commands
    parser.addCommand('init', initParser);
    parser.addCommand('list', listParser);
    parser.addCommand('configure', configureParser);
    parser.addCommand('set-project-ids', setProjectIdsParser);

    return CommandParser._(parser);
  }

  /// Gets the underlying ArgParser instance.
  ArgParser get parser => _parser;

  /// Parses the given arguments and returns the results.
  ArgResults parse(List<String> arguments) {
    return _parser.parse(arguments);
  }
}

/// Applies base flags to an argument parser.
/// This function defines the base flags once and applies them to any parser.
void _applyBaseFlags(ArgParser parser) {
  parser
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.')
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to configuration file (default: firebase_flavors.yaml).',
      defaultsTo: 'firebase_flavors.yaml',
    );
}
