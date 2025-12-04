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
}
