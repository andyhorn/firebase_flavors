import 'dart:io';

import 'logger.dart';
import 'services/firebase_project_service.dart';
import 'utils/config_reader.dart';
import 'utils/yaml_updater.dart';

/// Sets Firebase project IDs for flavors using various methods.
Future<void> setProjectIds({
  required String configPath,
  bool fromFiles = false,
  bool fromFirebase = false,
  bool interactive = false,
  String? projectIds,
}) async {
  logInfo('Reading configuration from $configPath...');
  final config = ConfigReader.readConfig(configPath);
  logSuccess('Configuration loaded successfully');

  final flavors = config.flavors.keys.toList();
  if (flavors.isEmpty) {
    logError('No flavors found in configuration file');
    exit(1);
  }

  final projectService = FirebaseProjectService();
  final yamlUpdater = YamlUpdater();
  final updates = <String, String>{};

  // Method 1: Auto-detect from existing config files
  if (fromFiles) {
    logInfo('Detecting project IDs from existing config files...');
    final detected = projectService.detectFromConfigFiles(config);
    if (detected.isEmpty) {
      logWarning('No project IDs detected from config files');
      logInfo(
        'Make sure google-services.json or GoogleService-Info.plist files exist',
      );
    } else {
      logInfo('Detected ${detected.length} project ID(s)');
      for (final entry in detected.entries) {
        logInfo('  ${entry.key}: ${entry.value}');
        updates[entry.key] = entry.value;
      }
    }
  }

  // Method 2: List from Firebase CLI and let user select
  if (fromFirebase) {
    logInfo('Fetching available Firebase projects...');
    final projects = await projectService.listProjects();
    if (projects.isEmpty) {
      logError('No Firebase projects found or Firebase CLI is not available');
      logInfo('Make sure you are logged in: firebase login');
      exit(1);
    }

    logInfo('Available Firebase projects:');
    for (int i = 0; i < projects.length; i++) {
      stdout.writeln('  ${i + 1}. ${projects[i]}');
    }

    for (final flavorName in flavors) {
      if (updates.containsKey(flavorName)) {
        logDebug('Skipping $flavorName (already set from files)');
        continue;
      }

      stdout.writeln('');
      stdout.write(
        'Select Firebase project for flavor "$flavorName" (1-${projects.length}): ',
      );
      final input = stdin.readLineSync()?.trim();
      if (input == null || input.isEmpty) {
        logWarning('Skipping $flavorName (no selection)');
        continue;
      }

      final index = int.tryParse(input);
      if (index == null || index < 1 || index > projects.length) {
        logWarning('Invalid selection for $flavorName, skipping');
        continue;
      }

      final selectedProject = projects[index - 1];
      updates[flavorName] = selectedProject.projectId;
      logInfo('Selected ${selectedProject.projectId} for $flavorName');
    }
  }

  // Method 3: Parse from command-line argument
  if (projectIds != null && projectIds.isNotEmpty) {
    final pairs = projectIds.split(',');
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length != 2) {
        logWarning(
          'Invalid project ID format: $pair (expected flavor:project-id)',
        );
        continue;
      }
      final flavorName = parts[0].trim();
      final projectId = parts[1].trim();
      if (flavorName.isEmpty || projectId.isEmpty) {
        logWarning('Invalid project ID format: $pair');
        continue;
      }
      if (!config.flavors.containsKey(flavorName)) {
        logWarning('Flavor "$flavorName" not found in configuration');
        continue;
      }
      updates[flavorName] = projectId;
      logInfo('Set project ID for $flavorName: $projectId');
    }
  }

  // Method 4: Interactive prompts
  if (interactive) {
    for (final flavorName in flavors) {
      if (updates.containsKey(flavorName)) {
        logDebug('Skipping $flavorName (already set)');
        continue;
      }

      stdout.writeln('');
      stdout.write('Enter Firebase project ID for flavor "$flavorName": ');
      final input = stdin.readLineSync()?.trim();
      if (input != null && input.isNotEmpty) {
        updates[flavorName] = input;
        logInfo('Set project ID for $flavorName: $input');
      } else {
        logWarning('Skipping $flavorName (empty input)');
      }
    }
  }

  // If no method was specified, default to interactive
  if (!fromFiles && !fromFirebase && projectIds == null && !interactive) {
    logInfo('No method specified, using interactive mode...');
    for (final flavorName in flavors) {
      stdout.writeln('');
      stdout.write('Enter Firebase project ID for flavor "$flavorName": ');
      final input = stdin.readLineSync()?.trim();
      if (input != null && input.isNotEmpty) {
        updates[flavorName] = input;
        logInfo('Set project ID for $flavorName: $input');
      } else {
        logWarning('Skipping $flavorName (empty input)');
      }
    }
  }

  // Apply updates
  if (updates.isEmpty) {
    logWarning('No project IDs to update');
    return;
  }

  logInfo('');
  logInfo('Updating configuration file...');
  final successCount = yamlUpdater.updateProjectIds(configPath, updates);
  if (successCount == updates.length) {
    logSuccess('Successfully updated $successCount project ID(s)');
  } else {
    logWarning('Updated $successCount of ${updates.length} project ID(s)');
  }
}
