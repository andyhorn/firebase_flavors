import 'dart:io';

import 'logger.dart';

String getPubspecVersion() {
  final pubspec = File('pubspec.yaml');
  
  if (!pubspec.existsSync()) {
    logError('pubspec.yaml not found');
    return 'unknown';
  }

  try {
    final content = pubspec.readAsStringSync();
    final version = content.split('version: ')[1].split('\n')[0].trim();
    logDebug('Read version from pubspec.yaml: $version');
    return version;
  } catch (e) {
    logError('Failed to read version from pubspec.yaml', e);
    return 'unknown';
  }
}
