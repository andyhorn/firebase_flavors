/// Exception thrown by firebase_flavors library code on user-facing failures.
///
/// The entry point (`bin/firebase_flavors.dart`) catches this and translates
/// it to the appropriate process exit code. Library code should not call
/// `exit()` directly.
class FirebaseFlavorsException implements Exception {
  FirebaseFlavorsException(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
