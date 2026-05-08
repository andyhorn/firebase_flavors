import 'package:yaml_edit/yaml_edit.dart';

import '../logger.dart';
import 'file_system.dart';

/// Updates `firebaseProjectId` fields in the firebase_flavors YAML file
/// while preserving comments and surrounding structure.
class YamlUpdater {
  YamlUpdater({FileSystem? fileSystem})
    : _fileSystem = fileSystem ?? DefaultFileSystem();

  final FileSystem _fileSystem;

  /// Updates the firebaseProjectId for [flavorName] in [configPath].
  ///
  /// Returns true if the update was applied, false if the flavor was missing
  /// or the file could not be read/written.
  bool updateProjectId(String configPath, String flavorName, String projectId) {
    if (!_fileSystem.fileExists(configPath)) {
      logError('Configuration file not found: $configPath');
      return false;
    }

    try {
      final editor = YamlEditor(_fileSystem.readFile(configPath));
      try {
        editor.update(['flavors', flavorName, 'firebaseProjectId'], projectId);
      } on ArgumentError {
        // yaml_edit's PathError extends ArgumentError; thrown when the path
        // does not resolve (e.g. flavor not present in the file).
        logWarning('Could not find flavor "$flavorName" in configuration file');
        return false;
      }
      _fileSystem.writeFile(configPath, editor.toString());
      logDebug(
        'Updated firebaseProjectId for flavor "$flavorName" to "$projectId"',
      );
      return true;
    } catch (e, stackTrace) {
      logError('Failed to update YAML file: $configPath', e, stackTrace);
      return false;
    }
  }

  /// Updates multiple flavor project IDs. Returns the number of successful
  /// updates.
  int updateProjectIds(
    String configPath,
    Map<String, String> flavorProjectIds,
  ) {
    var successCount = 0;
    for (final entry in flavorProjectIds.entries) {
      if (updateProjectId(configPath, entry.key, entry.value)) {
        successCount++;
      }
    }
    return successCount;
  }
}
