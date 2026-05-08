import 'package:xcode_parser/xcode_parser.dart';

/// Parses Xcode iOS project files (project.pbxproj, Info.plist) to extract
/// values needed for firebase_flavors configuration.
///
/// All methods are pure: they take string content and return values, mirroring
/// [GradleParser]. Callers handle file I/O and path resolution.
class IosProjectParser {
  /// Extracts the main app target's name and bundle ID from pbxproj content.
  ///
  /// Walks the project graph: PBXNativeTarget where productType is the iOS
  /// app type → its XCConfigurationList → first XCBuildConfiguration's
  /// PRODUCT_BUNDLE_IDENTIFIER. This avoids picking up bundle IDs from
  /// test, UI test, or extension targets.
  static ({String? targetName, String? bundleId}) extractFromPbxproj(
    String content,
  ) {
    final project = Pbxproj.parse(content);
    final objects = project.find<MapPbx>('objects');
    if (objects == null) return (targetName: null, bundleId: null);

    SectionPbx? section(String name) {
      for (final c in objects.childrenList) {
        if (c is SectionPbx && c.uuid == name) return c;
      }
      return null;
    }

    final nativeTargets = section('PBXNativeTarget');
    if (nativeTargets == null) return (targetName: null, bundleId: null);

    MapPbx? appTarget;
    for (final t in nativeTargets.childrenList) {
      if (t is! MapPbx) continue;
      final pt = t.find<MapEntryPbx>('productType')?.value.toString() ?? '';
      if (pt.contains('com.apple.product-type.application')) {
        appTarget = t;
        break;
      }
    }
    if (appTarget == null) return (targetName: null, bundleId: null);

    final targetName = _unquote(
      appTarget.find<MapEntryPbx>('name')?.value.toString(),
    );

    final cfgListUuid = appTarget
        .find<MapEntryPbx>('buildConfigurationList')
        ?.value
        .toString();
    final cfgLists = section('XCConfigurationList');
    MapPbx? cfgList;
    for (final c in cfgLists?.childrenList ?? const []) {
      if (c is MapPbx && c.uuid == cfgListUuid) {
        cfgList = c;
        break;
      }
    }
    final buildCfgs = cfgList?.find<ListPbx>('buildConfigurations');
    if (buildCfgs == null || buildCfgs.isEmpty) {
      return (targetName: targetName, bundleId: null);
    }

    final buildConfigsSection = section('XCBuildConfiguration');
    String? bundleId;
    for (final el in buildCfgs.toList()) {
      final uuid = el.value.toString();
      MapPbx? cfg;
      for (final c in buildConfigsSection?.childrenList ?? const []) {
        if (c is MapPbx && c.uuid == uuid) {
          cfg = c;
          break;
        }
      }
      final raw = cfg
          ?.find<MapPbx>('buildSettings')
          ?.find<MapEntryPbx>('PRODUCT_BUNDLE_IDENTIFIER')
          ?.value
          .toString();
      final candidate = _unquote(raw);
      if (candidate != null && !candidate.contains(r'$(')) {
        bundleId = candidate;
        break;
      }
    }

    return (targetName: targetName, bundleId: bundleId);
  }

  /// Extracts the user-facing app name from Info.plist content.
  ///
  /// Tries `CFBundleDisplayName` first (the user-facing name); falls back
  /// to `CFBundleName`. Returns null if neither is set.
  static String? extractAppNameFromInfoPlist(String content) {
    final displayName = _firstMatch(
      content,
      r'<key>\s*CFBundleDisplayName\s*</key>\s*<string>([^<]+)</string>',
    );
    if (displayName != null) return displayName;

    return _firstMatch(
      content,
      r'<key>\s*CFBundleName\s*</key>\s*<string>([^<]+)</string>',
    );
  }

  /// Strips surrounding double quotes from a pbxproj scalar, if present.
  static String? _unquote(String? value) {
    if (value == null) return null;
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static String? _firstMatch(String content, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(content);
    return match?.group(1)?.trim();
  }
}
