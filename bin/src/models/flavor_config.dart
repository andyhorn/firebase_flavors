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
    this.iosBundleId,
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
    final iosBundleId = map['iosBundleId'] as String?;

    String? normalizedSuffix;
    if (androidPackageSuffix == null || androidPackageSuffix.isEmpty) {
      normalizedSuffix = null;
    } else {
      final suffix = androidPackageSuffix.startsWith('.')
          ? androidPackageSuffix
          : '.$androidPackageSuffix';
      normalizedSuffix = suffix;
    }

    return FlavorConfig(
      name: name,
      firebaseProjectId: firebaseProjectId!,
      androidPackageSuffix: normalizedSuffix,
      dartOptionsOut: dartOptionsOut,
      androidSrcDir: androidSrcDir,
      iosConfigDir: iosConfigDir,
      platforms: platforms,
      iosBundleId: iosBundleId?.isEmpty == true ? null : iosBundleId,
    );
  }

  final String name;
  final String firebaseProjectId;
  final String? androidPackageSuffix;
  final String dartOptionsOut;
  final String androidSrcDir;
  final String iosConfigDir;
  final String? platforms;
  final String? iosBundleId;
}
