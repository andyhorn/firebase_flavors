## 3.0.0

### Breaking Changes

#### `iosConfigBase` default changed

The default `ios.configBase` is now `ios/<target>` (e.g. `ios/Runner`) derived from `ios.target`, replacing the previous `ios/Runner/Runner`. The init generator and the example `firebase_flavors.yaml` now also write `ios/Runner` so all four sources of truth (model default, generator output, example file, README docs) agree.

**Migration:** if you relied on the old implicit default, either:
- move your plist files from `ios/<target>/<target>/<flavor>/GoogleService-Info.plist` to `ios/<target>/<flavor>/GoogleService-Info.plist`, or
- set `ios.configBase: ios/<target>/<target>` explicitly in `firebase_flavors.yaml` to keep the previous layout.

#### Placeholder Firebase project IDs removed

`init` no longer writes `your-firebase-project-id-for-<flavor>` strings into the generated YAML. The `firebaseProjectId` field is emitted with an empty value and a TODO comment pointing at `set-project-ids`. `configure` now refuses to run if any selected flavor has an unset ID, instead of handing placeholders to `flutterfire`.

**Migration:** existing `firebase_flavors.yaml` files containing `firebaseProjectId: your-firebase-project-id-for-<flavor>` should be replaced with real IDs (run `firebase_flavors set-project-ids`).

#### `xcodeprojPath` YAML key now read with the documented casing

The model previously read `xcodeProjPath` (capital P). It now reads `xcodeprojPath` to match the README, init template, and example file. **If your `firebase_flavors.yaml` accidentally used `xcodeProjPath` to "match" the parser, rename it to `xcodeprojPath`.** Configurations that already used the documented casing (or relied on the default) are unaffected.

### Fixed

- iOS build-phase shell script no longer uses `declare -A`, which is unsupported by the bash 3.2 / POSIX sh that Xcode runs. Existing projects need to rerun `firebase_flavors configure --skip-firebase` once to regenerate the build phase.
- iOS build-phase shell script no longer fails for non-flavor configurations (e.g. plain `Debug` on a test target). Such configurations now exit 0 with a stderr notice.
- `firebase_flavors --version` reads the tool's own version instead of the host project's `pubspec.yaml`.
- pbxproj bundle ID extraction now walks the project graph to find the main app target, avoiding bundle IDs from test, UI test, or extension targets.
- `init` no longer recursively scans `ios/` looking for `Info.plist`; it reads the canonical `ios/<target>/Info.plist` only. Pods directories are no longer traversed.
- The "Flavor X not found in configuration" warning no longer prints twice per typo.
- `configure --help` and `set-project-ids --help` now show command-specific flags (`--skip-firebase`, `--from-files`, etc.) alongside global flags.
- `configure` no longer mutates the caller's `flavors` list.

### Changed

- `set-project-ids` interactive prompts now display the current value (or `unset`) and treat an empty response as "keep current" instead of skipping with a warning.
- `list` shows `[unset — run set-project-ids]` for flavors with no Firebase project ID.
- `logSuccess` no longer adds an emoji prefix on top of the printer's automatic level emoji.
- Library code throws `FirebaseFlavorsException` instead of calling `exit()` directly; only the entry point translates exceptions to exit codes.
- iOS pbxproj parsing extracted into `IosProjectParser` (`bin/src/utils/ios_project_parser.dart`) so it is testable independently from `init`.
- YAML field updates use `package:yaml_edit` instead of a hand-rolled line parser; comments and structure are now preserved.

### Added

- `IosProjectParser` and `YamlUpdater` test suites; `FirebaseProjectService` tests covering `extractFromGoogleServices`, `extractFromGoogleServiceInfo`, `detectFromConfigFiles`, and `listProjects`.
- `tool/sync_version.dart` generates `bin/src/version.dart` from `pubspec.yaml`. CI verifies the two stay in sync.

### Dependencies

- Added `xcode_parser ^2.1.0` for pbxproj parsing.
- Added `yaml_edit ^2.2.4` for surgical YAML field updates.

## 2.0.2

Fix iOS bundle IDs by replacing underscores with hyphens for Firebase compatibility.

## 2.0.1

Run `dart format` to fix formatting errors for CI workflow.

## 2.0.0

### Breaking Changes

#### Remove `iosBundleId` in favor of `iosBundleSuffix`

The behavior was changed to match the behavior of `androidPackageSuffix`.

Instead of supplying the full bundle ID, just supply the suffix. e.g.

`iosBundleId: com.example.app.dev` becomes `iosBundleSuffix: .dev`

## 1.1.0

### Added
- New `set-project-ids` command to set Firebase project IDs in the configuration file
  - `--from-files`: Auto-detect project IDs from existing `google-services.json` or `GoogleService-Info.plist` files
  - `--from-firebase`: Interactive selection from Firebase CLI projects list
  - `--interactive`: Prompt for project IDs interactively
  - `--project-ids`: Direct specification via command line as `flavor:project-id` pairs

### Changed
- Improved argument parsing and command handling architecture
- Enhanced error messages and command usage information

### Documentation
- Updated README with comprehensive documentation for the new `set-project-ids` command
- Added examples demonstrating different ways to use the new command

## 1.0.0

- Initial version.
