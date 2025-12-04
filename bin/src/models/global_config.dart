import 'package:yaml/yaml.dart';

import 'flavor_config.dart';

class GlobalConfig {
  const GlobalConfig({
    required this.appName,
    required this.baseBundleId,
    required this.androidSrcBase,
    required this.iosXcodeprojPath,
    required this.iosTarget,
    required this.iosConfigBase,
    required this.flavors,
  });

  factory GlobalConfig.fromYaml(YamlMap map) {
    return GlobalConfig(
      appName: map['appName'] as String,
      baseBundleId: map['baseBundleId'] as String,
      androidSrcBase:
          (map['android'] as YamlMap?)?['srcBase'] as String? ??
          'android/app/src',
      iosXcodeprojPath:
          (map['ios'] as YamlMap?)?['xcodeProjPath'] as String? ??
          'ios/Runner.xcodeproj',
      iosTarget: (map['ios'] as YamlMap?)?['target'] as String? ?? 'Runner',
      iosConfigBase:
          (map['ios'] as YamlMap?)?['configBase'] as String? ??
          'ios/Runner/Runner',
      flavors:
          (map['flavors'] as YamlMap?)?.map(
            (key, value) => MapEntry(
              key,
              FlavorConfig.fromYaml(
                YamlMap.wrap({...value as YamlMap, 'name': key}),
              ),
            ),
          ) ??
          {},
    );
  }

  final String appName;
  final String baseBundleId;
  final String androidSrcBase;
  final String iosXcodeprojPath;
  final String iosTarget;
  final String iosConfigBase;
  final Map<String, FlavorConfig> flavors;
}
