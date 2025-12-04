import 'dart:io';

import 'package:yaml/yaml.dart';

import '../logger.dart';
import '../models/global_config.dart';

/// Utility functions for reading and parsing configuration files.
class ConfigReader {
  /// Reads and parses a configuration file from the given path.
  ///
  /// [configPath] - Path to the configuration file (typically firebase_flavors.yaml)
  ///
  /// Returns the parsed [GlobalConfig].
  /// Exits with code 1 if the file doesn't exist or cannot be parsed.
  static GlobalConfig readConfig(String configPath) {
    final file = File(configPath);

    if (!file.existsSync()) {
      final absolutePath = file.absolute.path;
      logError('Configuration file $configPath not found.');
      logInfo('Expected location: $absolutePath');
      logInfo('Run "firebase_flavors init" to create a configuration file.');
      logInfo(
        'Or ensure you are running this command from your Flutter project root directory.',
      );
      exit(1);
    }

    logDebug('Reading configuration file: ${file.path}');
    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;

    try {
      final config = GlobalConfig.fromYaml(yaml);
      logDebug(
        'Configuration parsed successfully. Found ${config.flavors.length} flavor(s)',
      );
      return config;
    } catch (e, stackTrace) {
      logError(
        'Failed to parse configuration file: ${file.absolute.path}',
        e,
        stackTrace,
      );
      if (e is ArgumentError) {
        logInfo('Configuration error: ${e.message}');
        logInfo('Please check your $configPath file for syntax errors.');
      } else if (e.toString().contains('YAML')) {
        logInfo(
          'YAML syntax error detected. Please verify your configuration file format.',
        );
        logInfo(
          'Common issues: missing quotes, incorrect indentation, or invalid characters.',
        );
      }
      exit(1);
    }
  }

  /// Normalizes platform names from a comma-separated string.
  ///
  /// [platforms] - Comma-separated string of platform names (e.g., "android,ios")
  ///
  /// Returns a list of normalized platform names (lowercase, trimmed).
  /// Returns an empty list if [platforms] is null or empty.
  static List<String> normalizePlatforms(String? platforms) {
    if (platforms == null || platforms.isEmpty) {
      return <String>[];
    }

    return platforms
        .split(',')
        .map((p) => p.toLowerCase().trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}

