/// Utility class for parsing Gradle build files.
class GradleParser {
  /// Extracts the base applicationId from gradle content.
  /// Supports both `applicationId` and `namespace` properties.
  static String? extractApplicationId(String gradleContent) {
    // Try applicationId first (in defaultConfig or android block)
    final applicationIdPattern =
        '(?:defaultConfig|android)\\s*\\{[\\s\\S]*?applicationId\\s*[=:]\\s*["\']([^\'"]+)["\']';
    final applicationIdRegex = RegExp(applicationIdPattern, multiLine: true);
    final applicationIdMatch = applicationIdRegex.firstMatch(gradleContent);
    if (applicationIdMatch != null) {
      return applicationIdMatch.group(1);
    }

    // Fallback to namespace (for newer Gradle files)
    final namespacePattern = 'namespace\\s*[=:]\\s*["\']([^\'"]+)["\']';
    final namespaceRegex = RegExp(namespacePattern, multiLine: true);
    final namespaceMatch = namespaceRegex.firstMatch(gradleContent);
    if (namespaceMatch != null) {
      return namespaceMatch.group(1);
    }

    return null;
  }

  /// Extracts product flavors and their applicationIdSuffix values.
  /// Returns a map of flavor name -> suffix (empty string if no suffix).
  static Map<String, String> extractProductFlavors(
    String gradleContent,
    bool isKts,
  ) {
    final flavors = <String, String>{};

    // Find the productFlavors block
    final flavorsBlockPattern = r'productFlavors\s*\{((?:[^{}]|\{[^{}]*\})*)\}';
    final flavorsBlockRegex = RegExp(flavorsBlockPattern);
    final flavorsBlockMatch = flavorsBlockRegex.firstMatch(gradleContent);
    if (flavorsBlockMatch == null) {
      return flavors;
    }

    final flavorsBlockBody = flavorsBlockMatch.group(1)!;

    if (isKts) {
      // Kotlin DSL: create("flavorName") { ... }
      final createFlavorPattern =
          'create\\s*\\(\\s*["\']([A-Za-z0-9_]+)["\']\\s*\\)\\s*\\{([^{}]*(?:\\{[^{}]*\\}[^{}]*)*)\\}';
      final createFlavorRegex = RegExp(createFlavorPattern);

      for (final match in createFlavorRegex.allMatches(flavorsBlockBody)) {
        final flavorName = match.group(1)!;
        final flavorBody = match.group(2) ?? '';

        // Extract applicationIdSuffix from flavor body
        final suffixPattern =
            'applicationIdSuffix\\s*[=:]\\s*["\']([^\'"]*)["\']';
        final suffixRegex = RegExp(suffixPattern);
        final suffixMatch = suffixRegex.firstMatch(flavorBody);
        var suffix = suffixMatch?.group(1) ?? '';

        // Strip any leading dot when parsing (will be normalized later)
        if (suffix.isNotEmpty && suffix.startsWith('.')) {
          suffix = suffix.substring(1);
        }

        flavors[flavorName] = suffix.isEmpty ? '' : suffix;
      }
    } else {
      // Groovy DSL: flavorName { ... }
      final flavorNamePattern =
          r'\b([A-Za-z0-9_]+)\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}';
      final flavorNameRegex = RegExp(flavorNamePattern);

      for (final match in flavorNameRegex.allMatches(flavorsBlockBody)) {
        final flavorName = match.group(1)!;
        final flavorBody = match.group(2) ?? '';

        // Extract applicationIdSuffix from flavor body
        final suffixPattern =
            'applicationIdSuffix\\s*[=:]\\s*["\']([^\'"]*)["\']';
        final suffixRegex = RegExp(suffixPattern);
        final suffixMatch = suffixRegex.firstMatch(flavorBody);
        var suffix = suffixMatch?.group(1) ?? '';

        // Strip any leading dot when parsing (will be normalized later)
        if (suffix.isNotEmpty && suffix.startsWith('.')) {
          suffix = suffix.substring(1);
        }

        flavors[flavorName] = suffix.isEmpty ? '' : suffix;
      }
    }

    return flavors;
  }

  /// Extracts app name from manifestPlaceholders in gradle content.
  static String? extractAppName(String gradleContent) {
    // Look for manifestPlaceholders["appName"] = "App Name"
    final appNamePattern =
        'manifestPlaceholders\\s*\\["appName"\\]\\s*[=:]\\s*["\']([^\'"]+)["\']';
    final appNameRegex = RegExp(appNamePattern, multiLine: true);
    final appNameMatch = appNameRegex.firstMatch(gradleContent);
    if (appNameMatch != null) {
      return appNameMatch.group(1);
    }

    return null;
  }
}
