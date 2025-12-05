import 'dart:convert';
import 'dart:io';

import '../logger.dart';
import '../models/global_config.dart';
import '../utils/file_system.dart';
import '../utils/process_runner.dart';

/// Represents a Firebase project.
class FirebaseProject {
  const FirebaseProject({required this.projectId, required this.displayName});

  final String projectId;
  final String displayName;

  @override
  String toString() => '$displayName ($projectId)';
}

/// Service for extracting and managing Firebase project IDs.
class FirebaseProjectService {
  final ProcessRunner _processRunner;
  final FileSystem _fileSystem;

  FirebaseProjectService({ProcessRunner? processRunner, FileSystem? fileSystem})
    : _processRunner = processRunner ?? DefaultProcessRunner(),
      _fileSystem = fileSystem ?? DefaultFileSystem();

  /// Extracts project ID from a google-services.json file.
  ///
  /// Returns null if the file doesn't exist or cannot be parsed.
  String? extractFromGoogleServices(String filePath) {
    if (!_fileSystem.fileExists(filePath)) {
      logDebug('File not found: $filePath');
      return null;
    }

    try {
      final content = _fileSystem.readFile(filePath);
      final json = jsonDecode(content) as Map<String, dynamic>;
      final projectId = json['project_id'] as String?;
      if (projectId != null && projectId.isNotEmpty) {
        logDebug('Extracted project ID from $filePath: $projectId');
        return projectId;
      }
    } catch (e) {
      logDebug('Failed to parse google-services.json at $filePath: $e');
    }
    return null;
  }

  /// Extracts project ID from a GoogleService-Info.plist file.
  ///
  /// Returns null if the file doesn't exist or cannot be parsed.
  String? extractFromGoogleServiceInfo(String filePath) {
    if (!_fileSystem.fileExists(filePath)) {
      logDebug('File not found: $filePath');
      return null;
    }

    try {
      final content = _fileSystem.readFile(filePath);
      // Plist files can be XML or binary. Try XML first.
      // Look for <key>PROJECT_ID</key><string>...</string>
      final projectIdPattern = RegExp(
        r'<key>\s*PROJECT_ID\s*</key>\s*<string>([^<]+)</string>',
        caseSensitive: false,
      );
      final match = projectIdPattern.firstMatch(content);
      if (match != null) {
        final projectId = match.group(1)?.trim();
        if (projectId != null && projectId.isNotEmpty) {
          logDebug('Extracted project ID from $filePath: $projectId');
          return projectId;
        }
      }
    } catch (e) {
      logDebug('Failed to parse GoogleService-Info.plist at $filePath: $e');
    }
    return null;
  }

  /// Lists all Firebase projects available to the current user.
  ///
  /// Returns an empty list if Firebase CLI is not available or not authenticated.
  Future<List<FirebaseProject>> listProjects() async {
    try {
      logDebug('Querying Firebase CLI for available projects...');
      final result = await _processRunner.run('firebase', [
        'projects:list',
        '--json',
      ]);

      if (result.exitCode != 0) {
        logDebug('Firebase CLI returned exit code: ${result.exitCode}');
        if (result.stderr.toString().isNotEmpty) {
          logDebug('Firebase CLI stderr: ${result.stderr}');
        }
        return [];
      }

      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        logDebug('Firebase CLI returned empty output');
        return [];
      }

      try {
        final json = jsonDecode(output) as Map<String, dynamic>;
        final results = json['result'] as List<dynamic>?;
        if (results == null) {
          return [];
        }

        final projects = <FirebaseProject>[];
        for (final item in results) {
          final project = item as Map<String, dynamic>;
          final projectId = project['projectId'] as String?;
          final displayName = project['displayName'] as String?;
          if (projectId != null && projectId.isNotEmpty) {
            projects.add(
              FirebaseProject(
                projectId: projectId,
                displayName: displayName ?? projectId,
              ),
            );
          }
        }

        logDebug('Found ${projects.length} Firebase project(s)');
        return projects;
      } catch (e) {
        logDebug('Failed to parse Firebase CLI JSON output: $e');
        return [];
      }
    } on ProcessException catch (e) {
      logDebug('Failed to run Firebase CLI: $e');
      return [];
    } catch (e) {
      logDebug('Unexpected error querying Firebase projects: $e');
      return [];
    }
  }

  /// Detects project IDs from existing config files in the project.
  ///
  /// Returns a map of flavor name to project ID.
  Map<String, String> detectFromConfigFiles(GlobalConfig config) {
    final detected = <String, String>{};

    for (final entry in config.flavors.entries) {
      final flavorName = entry.key;
      final flavorConfig = entry.value;

      // Try Android config file first
      final androidPath =
          '${config.androidSrcBase}/${flavorConfig.androidSrcDir}/google-services.json';
      final androidProjectId = extractFromGoogleServices(androidPath);
      if (androidProjectId != null) {
        detected[flavorName] = androidProjectId;
        logDebug(
          'Detected project ID for $flavorName from Android: $androidProjectId',
        );
        continue;
      }

      // Try iOS config file
      final iosPath =
          '${config.iosConfigBase}/${flavorConfig.iosConfigDir}/GoogleService-Info.plist';
      final iosProjectId = extractFromGoogleServiceInfo(iosPath);
      if (iosProjectId != null) {
        detected[flavorName] = iosProjectId;
        logDebug('Detected project ID for $flavorName from iOS: $iosProjectId');
      }
    }

    return detected;
  }
}
