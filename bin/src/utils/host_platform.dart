import 'dart:io';

/// Operating System-specific constants for terminal commands, directories, etc.
///
/// Supports Windows, Mac, and Linux hosts. Others will throw an [UnknownPlatformException].
abstract class HostPlatformConfig {

    /// Returns the expected location for the dart pub cache.
    ///
    /// * For Unix systems this is usually a hidden folder in your home directory.
    /// * For Windows this is usually in your AppData folder.
    static String pubCacheLocation() {
        if (Platform.isWindows) {
            return '%APPDATA%/Pub/Cache/bin';
        } else if (Platform.isMac || Platform.isLinux) {
            return '~/.pub/cache/bin';   
        } else {
            throw UnknownPlatformException('Unknown platform - ${Platform.operatingSystem}');
        }
    }

    /// Returns the expected name of the `flutterfire_cli` command.
    ///
    /// * For Unix systems this is usually just `flutterfire`.
    /// * For Windows this is usually `flutterfire.bat`, but powershell terminals allow the Unix method, too.
    static String flutterfireCli() {
        if (Platform.isWindows) {
            return 'flutterfire.bat';    
        } else if (Platform.isMac || Platform.isLinux) {
            return 'flutterfire';        
        } else {
            throw UnknownPlatformException('Unknown platform - ${Platform.operatingSystem}');
        }
    }
}

