import 'package:platform/platform.dart';

/// Thrown when an unknown platform is attempting to run an OS-sensitive operation.
class UnknownPlatformException implements Exception {
  const UnknownPlatformException(this.platform);

  /// The OS that was used when the exception was thrown.
  final Platform platform;

  @override
  String toString() {
    return 'Unknown platform exception - ${platform.operatingSystem}';
  }
}
