import 'dart:io';

import '../logger.dart';
import '../models/flavor_config.dart';
import '../models/global_config.dart';
import '../utils/process_runner.dart';

/// Service for interacting with the Firebase CLI (flutterfire).
class FirebaseService {
  final ProcessRunner _processRunner;

  FirebaseService({ProcessRunner? processRunner})
    : _processRunner = processRunner ?? DefaultProcessRunner();

  /// Configures a flavor using flutterfire CLI.
  ///
  /// [config] - Global configuration
  /// [flavorConfig] - Flavor-specific configuration
  /// [platformNames] - List of platform names to configure (e.g., ['android', 'ios'])
  ///
  /// Throws [ProcessException] if flutterfire command cannot be started.
  /// Exits with non-zero code if flutterfire configure fails.
  Future<void> configureFlavor(
    GlobalConfig config,
    FlavorConfig flavorConfig,
    List<String> platformNames,
  ) async {
    final android = platformNames.isEmpty || platformNames.contains('android');
    final ios = platformNames.isEmpty || platformNames.contains('ios');

    final args = [
      'configure',
      '--project=${flavorConfig.firebaseProjectId}',
      '--out=${flavorConfig.dartOptionsOut}',
      if (platformNames.isNotEmpty) ...[
        '--platforms=${platformNames.join(',')}',
      ],
      if (android) ...[
        '--android-package-name=${config.baseBundleId}${flavorConfig.androidPackageSuffix}',
        '--android-out=${config.androidSrcBase}/${flavorConfig.androidSrcDir}/google-services.json',
      ],
      if (ios) ...[
        '--ios-bundle-id=${flavorConfig.iosBundleId ?? config.baseBundleId}',
        '--ios-out=${config.iosConfigBase}/${flavorConfig.iosConfigDir}/GoogleService-Info.plist',
        '--ios-build-config=Debug-${flavorConfig.name}',
      ],
      '--yes',
    ];

    logDebug('Running flutterfire with args: ${args.join(' ')}');
    logInfo('Project: ${flavorConfig.firebaseProjectId}');
    if (android) {
      logDebug(
        'Android package: ${config.baseBundleId}${flavorConfig.androidPackageSuffix}',
      );
    }
    if (ios) {
      final iosBundleId = flavorConfig.iosBundleId ?? config.baseBundleId;
      logDebug('iOS bundle ID: $iosBundleId');
    }
    logDebug('Dart options out: ${flavorConfig.dartOptionsOut}');

    Process process;
    try {
      process = await _processRunner.start(
        'flutterfire',
        args,
        mode: ProcessStartMode.inheritStdio,
      );
    } on ProcessException catch (e, stackTrace) {
      logError('Failed to start flutterfire command.', e, stackTrace);
      logInfo(
        'This usually means flutterfire CLI is not installed or not on your PATH.',
      );
      logInfo('Install it with: dart pub global activate flutterfire_cli');
      logInfo(
        'Then ensure your PATH includes: ${Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']}/.pub-cache/bin',
      );
      exit(1);
    }

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      logError(
        'flutterfire configure failed for flavor "${flavorConfig.name}"',
      );
      logError('Exit code: $exitCode');
      logInfo('Common causes:');
      logInfo(
        '  - Firebase project ID "${flavorConfig.firebaseProjectId}" not found or inaccessible',
      );
      logInfo(
        '  - Bundle ID or package name not registered in Firebase project',
      );
      logInfo('  - Network connectivity issues');
      logInfo('  - Firebase authentication required (run: firebase login)');
      logInfo('Check the flutterfire output above for more details.');
      exit(exitCode);
    }
  }
}
