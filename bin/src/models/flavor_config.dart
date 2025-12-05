import 'package:yaml/yaml.dart';

class FlavorConfig {
  const FlavorConfig({
    required this.name,
    required this.firebaseProjectId,
    required this.androidPackageSuffix,
    required this.dartOptionsOut,
    required this.androidSrcDir,
    required this.iosConfigDir,
    required this.platforms,
    this.iosBundleSuffix,
  });

  factory FlavorConfig.fromYaml(YamlMap map) {
    final name = map['name'] as String;
    final firebaseProjectId = map['firebaseProjectId'] as String?;

    if (firebaseProjectId?.isEmpty ?? true) {
      throw ArgumentError('firebaseProjectId is required', 'firebaseProjectId');
    }

    final androidPackageSuffix = map['androidPackageSuffix'] as String?;
    final dartOptionsOut =
        map['dartOptionsOut'] as String? ?? 'lib/firebase_options_$name.dart';
    final androidSrcDir = map['androidSrcDir'] as String? ?? name;
    final iosConfigDir = map['iosConfigDir'] as String? ?? name;
    final platforms = map['platforms'] as String?;
    final iosBundleSuffix = map['iosBundleSuffix'] as String?;

    return FlavorConfig(
      name: name,
      firebaseProjectId: firebaseProjectId!,
      androidPackageSuffix: _normalizeSuffix(androidPackageSuffix),
      dartOptionsOut: dartOptionsOut,
      androidSrcDir: androidSrcDir,
      iosConfigDir: iosConfigDir,
      platforms: platforms,
      iosBundleSuffix: _normalizeSuffix(iosBundleSuffix),
    );
  }

  /// Normalizes a bundle ID suffix by ensuring it has a leading dot.
  ///
  /// Returns `null` if the suffix is `null` or empty.
  /// Otherwise, returns the suffix with a leading dot (adding one if missing).
  static String? _normalizeSuffix(String? suffix) {
    if (suffix == null || suffix.isEmpty) {
      return null;
    }
    return suffix.startsWith('.') ? suffix : '.$suffix';
  }

  /// Returns the Android bundle ID by appending the suffix to the base bundle ID.
  String getAndroidBundleId(String baseBundleId) {
    return baseBundleId + (androidPackageSuffix ?? '');
  }

  /// Returns the iOS bundle ID by appending the suffix to the base bundle ID.
  String getIosBundleId(String baseBundleId) {
    return baseBundleId + (iosBundleSuffix ?? '');
  }

  final String name;
  final String firebaseProjectId;
  final String? androidPackageSuffix;
  final String dartOptionsOut;
  final String androidSrcDir;
  final String iosConfigDir;
  final String? platforms;
  final String? iosBundleSuffix;
}
