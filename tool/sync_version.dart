import 'dart:io';

/// Syncs `bin/src/version.dart` with the `version:` field in `pubspec.yaml`.
///
/// Usage:
///   dart run tool/sync_version.dart           # write version.dart
///   dart run tool/sync_version.dart --check   # exit 1 if out of sync
void main(List<String> args) {
  final check = args.contains('--check');

  final pubspecVersion = _readPubspecVersion();
  final versionFile = File('bin/src/version.dart');
  final expected = _renderVersionFile(pubspecVersion);

  if (check) {
    if (!versionFile.existsSync()) {
      stderr.writeln(
        'bin/src/version.dart is missing. Run: dart run tool/sync_version.dart',
      );
      exit(1);
    }
    final actual = versionFile.readAsStringSync();
    if (actual != expected) {
      stderr.writeln(
        'bin/src/version.dart is out of sync with pubspec.yaml '
        '(expected version: $pubspecVersion).',
      );
      stderr.writeln('Run: dart run tool/sync_version.dart');
      exit(1);
    }
    stdout.writeln('version.dart in sync ($pubspecVersion).');
    return;
  }

  versionFile.parent.createSync(recursive: true);
  versionFile.writeAsStringSync(expected);
  stdout.writeln('Wrote bin/src/version.dart ($pubspecVersion).');
}

String _readPubspecVersion() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml not found. Run from the package root.');
    exit(1);
  }

  final pattern = RegExp(r'^version:\s*([^\s#]+)', multiLine: true);
  final match = pattern.firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    stderr.writeln('Could not find a version: field in pubspec.yaml.');
    exit(1);
  }
  return match.group(1)!.split('+').first;
}

String _renderVersionFile(String version) =>
    '// Generated from pubspec.yaml by tool/sync_version.dart.\n'
    '// Do not edit by hand. Run: dart run tool/sync_version.dart\n'
    "const packageVersion = '$version';\n";
