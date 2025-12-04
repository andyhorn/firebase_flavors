/// Utility functions for iOS-related operations.
class IosUtils {
  /// Normalizes config base path relative to project directory.
  /// The Xcode build phase runs from within the ios directory,
  /// so strip a leading "ios/" when present.
  static String configBaseRelativeToProjectDir(String configBase) {
    if (configBase.startsWith('ios/')) {
      return configBase.substring(4);
    }

    return configBase;
  }

  /// Infers flavor names from iOS build configuration names.
  /// E.g., "Debug-production", "Release-staging" -> ["production", "staging"]
  static List<String> inferFlavorsFromBuildConfigs(List<String>? buildConfigs) {
    if (buildConfigs == null || buildConfigs.isEmpty) {
      return [];
    }

    final flavors = <String>{};
    for (final config in buildConfigs) {
      // Extract flavor from config names like "Debug-production", "Release-staging"
      final parts = config.split('-');
      if (parts.length > 1) {
        // Skip the build type (Debug/Release/Profile) and get the flavor
        final flavor = parts.sublist(1).join('-');
        if (flavor.isNotEmpty) {
          flavors.add(flavor);
        }
      }
    }

    return flavors.toList()..sort();
  }
}
