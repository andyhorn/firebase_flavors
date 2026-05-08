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
    final ios = map['ios'] as YamlMap?;
    final iosTarget = ios?['target'] as String? ?? 'Runner';
    return GlobalConfig(
      appName: map['appName'] as String,
      baseBundleId: map['baseBundleId'] as String,
      androidSrcBase:
          (map['android'] as YamlMap?)?['srcBase'] as String? ??
          'android/app/src',
      iosXcodeprojPath:
          ios?['xcodeprojPath'] as String? ?? 'ios/$iosTarget.xcodeproj',
      iosTarget: iosTarget,
      iosConfigBase: ios?['configBase'] as String? ?? 'ios/$iosTarget',
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
