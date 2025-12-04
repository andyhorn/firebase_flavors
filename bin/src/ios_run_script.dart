import 'dart:io';

import 'logger.dart';
import 'models/global_config.dart';

/// Ensures the Xcode project has a run script that copies the
/// flavor-specific GoogleService-Info.plist into the build output.
Future<void> ensureIosGoogleServicesRunScript(GlobalConfig config) async {
  final xcodeprojPath = config.iosXcodeprojPath;
  final xcodeprojDir = Directory(xcodeprojPath);

  if (!xcodeprojDir.existsSync()) {
    logWarning(
      'Xcode project not found at ${xcodeprojPath}, skipping iOS run script setup.',
    );

    return;
  }

  final tempDir = Directory.systemTemp.createTempSync('firebase_flavors_');
  final rubyScriptFile = File('${tempDir.path}/add_copy_google_services.rb');

  try {
    rubyScriptFile.writeAsStringSync(_rubyScriptContents());

    final configBaseRelative = _configBaseRelativeToProjectDir(
      config.iosConfigBase,
    );

    // Build mapping from flavor name to iosConfigDir
    // Format: "flavor1:iosConfigDir1,flavor2:iosConfigDir2"
    final flavorToConfigDirMap = <String, String>{};
    for (final entry in config.flavors.entries) {
      flavorToConfigDirMap[entry.key] = entry.value.iosConfigDir;
    }
    final flavorMapping = flavorToConfigDirMap.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');

    // Convert to absolute path for reliability across working directories
    final absoluteXcodeprojPath = xcodeprojDir.absolute.path;

    final result = await Process.run('ruby', [
      rubyScriptFile.path,
      absoluteXcodeprojPath,
      config.iosTarget,
      configBaseRelative,
      flavorMapping,
    ]);

    final stdoutText = (result.stdout ?? '').toString().trim();
    final stderrText = (result.stderr ?? '').toString().trim();

    if (result.exitCode != 0) {
      logWarning(
        'Could not add the iOS copy script (ruby exit code ${result.exitCode}).',
      );

      if (stdoutText.isNotEmpty) {
        logDebug(stdoutText);
      }

      if (stderrText.isNotEmpty) {
        logDebug(stderrText);
      }

      logInfo(
        'Ensure Ruby is installed and the xcodeproj gem is available: '
        '`gem install xcodeproj`.',
      );

      return;
    }

    if (stdoutText.isNotEmpty) {
      logDebug(stdoutText);
    }

    if (stderrText.isNotEmpty) {
      logDebug(stderrText);
    }

    logSuccess(
      'Ensured Xcode run script "Copy GoogleService-Info.plist for Flavor" is added.',
    );
  } on ProcessException catch (e, stackTrace) {
    logWarning(
      'Failed to run Ruby to update the Xcode project. '
      'Install Ruby and the xcodeproj gem (`gem install xcodeproj`).',
    );

    logDebug('Ruby invocation error: $e');
    logDebug(stackTrace.toString());
  } finally {
    if (rubyScriptFile.existsSync()) {
      rubyScriptFile.deleteSync();
    }

    if (tempDir.existsSync()) {
      tempDir.deleteSync();
    }
  }
}

String _configBaseRelativeToProjectDir(String configBase) {
  // The Xcode build phase runs from within the ios directory,
  // so strip a leading "ios/" when present.
  if (configBase.startsWith('ios/')) {
    return configBase.substring(4);
  }

  return configBase;
}

String _rubyScriptContents() => r'''
#!/usr/bin/env ruby

project_path, target_name, config_base, flavor_mapping = ARGV

if project_path.nil? || target_name.nil? || config_base.nil? || flavor_mapping.nil?
  warn 'Usage: ruby add_copy_google_services.rb <project_path> <target_name> <config_base> <flavor_mapping>'
  exit 1
end

begin
  require 'xcodeproj'
rescue LoadError
  warn 'Missing required gem "xcodeproj". Install with `gem install xcodeproj`.'
  exit 1
end

unless File.directory?(project_path)
  warn "Xcode project not found at #{project_path}"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  warn "Target #{target_name} not found in project #{project_path}"
  exit 1
end

script_name = 'Copy GoogleService-Info.plist for Flavor'

# Parse flavor mapping: "flavor1:iosConfigDir1,flavor2:iosConfigDir2"
flavor_map = {}
flavor_mapping.split(',').each do |pair|
  flavor_name, ios_config_dir = pair.split(':', 2)
  flavor_map[flavor_name] = ios_config_dir if flavor_name && ios_config_dir
end

# Generate bash script with flavor mapping
flavor_map_script = flavor_map.map { |flavor, config_dir|
  "    [\"#{flavor}\"]=\"#{config_dir}\""
}.join("\n")

shell_script = <<~SCRIPT
  FLAVOR_NAME="${CONFIGURATION#*-}"
  CONFIG_BASE="${PROJECT_DIR}/#{config_base}"
  
  # Map flavor name to iosConfigDir
  declare -A FLAVOR_TO_CONFIG_DIR=(
#{flavor_map_script}
  )
  
  # Get the config directory for this flavor, fallback to flavor name if not found
  IOS_CONFIG_DIR="${FLAVOR_TO_CONFIG_DIR[$FLAVOR_NAME]:-$FLAVOR_NAME}"
  
  PLIST_SOURCE="${CONFIG_BASE}/${IOS_CONFIG_DIR}/GoogleService-Info.plist"
  PLIST_DESTINATION="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

  if [ -f "${PLIST_SOURCE}" ]; then
    cp "${PLIST_SOURCE}" "${PLIST_DESTINATION}"
    echo "Copied ${PLIST_SOURCE} to ${PLIST_DESTINATION}"
  else
    echo "No GoogleService-Info.plist found for configuration ${CONFIGURATION} (expected ${PLIST_SOURCE})" >&2
    exit 1
  fi
SCRIPT

existing_phase = target.shell_script_build_phases.find { |phase| phase.name == script_name }

if existing_phase
  existing_phase.shell_script = shell_script
else
  new_phase = target.new_shell_script_build_phase(script_name)
  new_phase.shell_script = shell_script
end

project.save
puts "Added '#{script_name}' run script to target #{target_name}"
''';
