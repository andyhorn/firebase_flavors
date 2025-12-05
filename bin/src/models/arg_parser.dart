import 'package:args/args.dart';

ArgParser getArgParser() {
  return ArgParser()
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
    ..addFlag('force', help: 'Overwrite existing files.')
    ..addFlag(
      'skip-firebase',
      negatable: false,
      help: 'Skip Firebase configuration.',
    )
    ..addFlag('skip-xcode', negatable: false, help: 'Skip Xcode script setup.')
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
      help: 'Comma-separated list of flavor:project-id pairs (e.g., dev:project-id-1,prod:project-id-2).',
    )
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to configuration file (default: firebase_flavors.yaml).',
      defaultsTo: 'firebase_flavors.yaml',
    );
}
