import 'dart:io';

/// Thrown when an unknown platform is attempting to run an OS-sensitive operation.
class UnknownPlatformException implements Exception {
  @override
  String toString() {
    return 'Unknown platform exception - ${Platform.operatingSystem}';
  }
}
