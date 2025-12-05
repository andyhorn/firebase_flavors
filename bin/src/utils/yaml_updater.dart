import '../logger.dart';
import 'file_system.dart';

/// Utility for updating YAML configuration files while preserving structure.
class YamlUpdater {
  final FileSystem _fileSystem;

  YamlUpdater({FileSystem? fileSystem})
    : _fileSystem = fileSystem ?? DefaultFileSystem();

  /// Updates the firebaseProjectId for a specific flavor in the YAML file.
  ///
  /// Returns true if the update was successful, false otherwise.
  bool updateProjectId(String configPath, String flavorName, String projectId) {
    if (!_fileSystem.fileExists(configPath)) {
      logError('Configuration file not found: $configPath');
      return false;
    }

    try {
      final content = _fileSystem.readFile(configPath);
      final lines = content.split('\n');
      final updatedLines = <String>[];
      bool inFlavorSection = false;
      bool foundFlavor = false;
      bool updated = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        // Check if we're entering the flavors section
        if (trimmed == 'flavors:' || trimmed.startsWith('flavors:')) {
          inFlavorSection = true;
          updatedLines.add(line);
          continue;
        }

        // Check if we're entering a specific flavor section
        if (inFlavorSection &&
            !line.startsWith(' ') &&
            !line.startsWith('\t')) {
          // We've left the flavors section or entered a new top-level key
          if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
            inFlavorSection = false;
          }
        }

        // Check if this is the flavor we're looking for
        if (inFlavorSection && trimmed == '$flavorName:') {
          foundFlavor = true;
          updatedLines.add(line);
          continue;
        }

        // If we're in the target flavor section, look for firebaseProjectId
        if (foundFlavor && inFlavorSection) {
          // Check if this is the firebaseProjectId line
          if (trimmed.startsWith('firebaseProjectId:')) {
            // Update the project ID, preserving indentation
            final indent = line.substring(
              0,
              line.length - line.trimLeft().length,
            );
            updatedLines.add('${indent}firebaseProjectId: $projectId');
            updated = true;
            continue;
          }

          // If we hit a non-indented line (new flavor or end of flavors), we're done
          if (trimmed.isNotEmpty &&
              !trimmed.startsWith('#') &&
              !line.startsWith(' ') &&
              !line.startsWith('\t')) {
            // We've left the flavor section, insert firebaseProjectId if not found
            if (!updated) {
              // Find the indentation level of the flavor
              final flavorIndent = _getIndent(lines[i - 1]);
              final indent =
                  '$flavorIndent  '; // Add 2 spaces for nested property
              // Insert before the current line
              updatedLines.insert(
                updatedLines.length - 1,
                '${indent}firebaseProjectId: $projectId',
              );
              updated = true;
            }
            foundFlavor = false;
            inFlavorSection =
                trimmed == 'flavors:' || trimmed.startsWith('flavors:');
          }
        }

        updatedLines.add(line);
      }

      // If we found the flavor but didn't update (firebaseProjectId was missing)
      if (foundFlavor && !updated) {
        // Find the last line of the flavor section and add it there
        for (int i = updatedLines.length - 1; i >= 0; i--) {
          final line = updatedLines[i];
          if (line.trim() == '$flavorName:') {
            // Find the indentation of the next non-empty line or use default
            String indent = '    ';
            for (int j = i + 1; j < updatedLines.length; j++) {
              final nextLine = updatedLines[j];
              if (nextLine.trim().isNotEmpty &&
                  !nextLine.trim().startsWith('#')) {
                indent = _getIndent(nextLine);
                break;
              }
            }
            updatedLines.insert(
              i + 1,
              '${indent}firebaseProjectId: $projectId',
            );
            updated = true;
            break;
          }
        }
      }

      if (updated) {
        final updatedContent = updatedLines.join('\n');
        _fileSystem.writeFile(configPath, updatedContent);
        logDebug(
          'Updated firebaseProjectId for flavor "$flavorName" to "$projectId"',
        );
        return true;
      } else {
        logWarning('Could not find flavor "$flavorName" in configuration file');
        return false;
      }
    } catch (e, stackTrace) {
      logError('Failed to update YAML file: $configPath', e, stackTrace);
      return false;
    }
  }

  /// Gets the indentation (whitespace) from the beginning of a line.
  String _getIndent(String line) {
    if (line.isEmpty) return '';
    final match = RegExp(r'^(\s*)').firstMatch(line);
    return match?.group(1) ?? '';
  }

  /// Updates multiple project IDs at once.
  ///
  /// Returns the number of successfully updated flavors.
  int updateProjectIds(
    String configPath,
    Map<String, String> flavorProjectIds,
  ) {
    int successCount = 0;
    for (final entry in flavorProjectIds.entries) {
      if (updateProjectId(configPath, entry.key, entry.value)) {
        successCount++;
      }
    }
    return successCount;
  }
}
