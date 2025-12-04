import 'dart:io';

import 'logger.dart';

/// Checks if a command is available on the system PATH.
Future<bool> _isCommandAvailable(String command) async {
  try {
    final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
      command,
    ]);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

/// Checks if flutterfire CLI is installed and available.
Future<bool> checkFlutterfire() async {
  logDebug('Checking for flutterfire CLI...');
  final isAvailable = await _isCommandAvailable('flutterfire');

  if (!isAvailable) {
    logError('flutterfire CLI is not installed or not found on your PATH.');
    logInfo('Install it with: dart pub global activate flutterfire_cli');
    logInfo(
      'Make sure your PATH includes: ${Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']}/.pub-cache/bin',
    );
  } else {
    logDebug('flutterfire CLI found');
  }

  return isAvailable;
}

/// Checks if Ruby is installed and available.
Future<bool> checkRuby() async {
  logDebug('Checking for Ruby...');
  final isAvailable = await _isCommandAvailable('ruby');

  if (!isAvailable) {
    logError('Ruby is not installed or not found on your PATH.');
    logInfo(
      'Install Ruby: https://www.ruby-lang.org/en/documentation/installation/',
    );
    if (Platform.isMacOS) {
      logInfo(
        'On macOS, Ruby may already be installed. Try: /usr/bin/ruby --version',
      );
    }
  } else {
    logDebug('Ruby found');
  }

  return isAvailable;
}

/// Checks if the xcodeproj gem is installed.
Future<bool> checkXcodeprojGem() async {
  logDebug('Checking for xcodeproj gem...');

  try {
    final result = await Process.run('gem', ['list', 'xcodeproj', '-i']);

    final isInstalled =
        result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty;

    if (!isInstalled) {
      logError('xcodeproj gem is not installed.');
      logInfo('Install it with: gem install xcodeproj');
    } else {
      logDebug('xcodeproj gem found');
    }

    return isInstalled;
  } catch (e) {
    logError('Failed to check for xcodeproj gem: $e');
    logInfo('Install it with: gem install xcodeproj');
    return false;
  }
}

/// Checks all prerequisites needed for Firebase configuration.
/// Returns true if all required prerequisites are available.
/// [needsIos] indicates if iOS configuration will be performed.
Future<bool> checkPrerequisites({required bool needsIos}) async {
  logInfo('Checking prerequisites...');

  var allPassed = true;

  // Always check for flutterfire
  if (!await checkFlutterfire()) {
    allPassed = false;
  }

  // Only check Ruby and xcodeproj if iOS configuration is needed
  if (needsIos) {
    if (!await checkRuby()) {
      allPassed = false;
    } else if (!await checkXcodeprojGem()) {
      allPassed = false;
    }
  }

  if (allPassed) {
    logSuccess('All prerequisites met');
  } else {
    logError(
      'Some prerequisites are missing. Please install them and try again.',
    );
  }

  return allPassed;
}
