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
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to configuration file (default: firebase_flavors.yaml).',
      defaultsTo: 'firebase_flavors.yaml',
    );
}
