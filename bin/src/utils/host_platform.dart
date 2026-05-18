import 'exceptions.dart';
import 'package:platform/platform.dart';
import 'package:meta/meta.dart';

/// Wrapper around [Platform] for testing.
Platform _platform = LocalPlatform();

/// Operating System-specific constants for terminal commands, directories, etc.
///
/// Supports Windows, Mac, and Linux hosts. Others will throw an
/// [UnknownPlatformException].
abstract class HostPlatformConfig {
  @visibleForTesting
  static void overridePlatform(Platform platform) {
    _platform = platform;
  }

  /// Returns the expected location for the dart pub cache.
  ///
  /// * For Unix systems this is usually a hidden folder in your home directory.
  /// * For Windows this is usually in your AppData folder.
  static String get pubCacheLocation {
    switch (_platform.operatingSystem) {
      case 'linux':
      case 'macos':
        return '${_platform.environment['HOME']}/.pub/cache/bin';
      case 'windows':
        return '${_platform.environment['USERPROFILE']}'
            '\\AppData\\Local\\Pub\\Cache\\bin';
      case _:
        throw UnknownPlatformException(_platform);
    }
  }

  /// Returns the expected name of the `flutterfire_cli` command.
  ///
  /// * For Unix systems this is usually just `flutterfire`.
  /// * For Windows this is usually `flutterfire.bat`, but powershell terminals
  ///   allow the Unix method, too.
  static String get flutterfireCli {
    switch (_platform.operatingSystem) {
      case 'linux':
      case 'macos':
        return 'flutterfire';
      case 'windows':
        return 'flutterfire.bat';
      case _:
        throw UnknownPlatformException(_platform);
    }
  }
}
