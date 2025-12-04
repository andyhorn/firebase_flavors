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
  });

  factory FlavorConfig.fromYaml(YamlMap map) {
    final name = map['name'] as String;
    final firebaseProjectId = map['firebaseProjectId'] as String?;

    if (firebaseProjectId?.isEmpty ?? true) {
      throw ArgumentError('firebaseProjectId is required', 'firebaseProjectId');
    }

    final androidPackageSuffix =
        map['androidPackageSuffix'] as String? ?? '.$name';
    final dartOptionsOut =
        map['dartOptionsOut'] as String? ?? 'lib/firebase_options_$name.dart';
    final androidSrcDir = map['androidSrcDir'] as String? ?? name;
    final iosConfigDir = map['iosConfigDir'] as String? ?? name;
    final platforms = map['platforms'] as String?;

    return FlavorConfig(
      name: name,
      firebaseProjectId: firebaseProjectId!,
      androidPackageSuffix: androidPackageSuffix,
      dartOptionsOut: dartOptionsOut,
      androidSrcDir: androidSrcDir,
      iosConfigDir: iosConfigDir,
      platforms: platforms,
    );
  }

  final String name;
  final String firebaseProjectId;
  final String androidPackageSuffix;
  final String dartOptionsOut;
  final String androidSrcDir;
  final String iosConfigDir;
  final String? platforms;
}
