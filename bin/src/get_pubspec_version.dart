import 'dart:io';

String getPubspecVersion() {
  final pubspec = File('pubspec.yaml');
  final content = pubspec.readAsStringSync();
  final version = content.split('version: ')[1].split('\n')[0].trim();
  return version;
}
