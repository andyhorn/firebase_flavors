# Testing Notes

## Layout

- `test/models/` — model parsing and helpers (`FlavorConfig`, `GlobalConfig`).
- `test/utils/` — pure utilities (`GradleParser`, `IosProjectParser`,
  `YamlGenerator`, `YamlUpdater`, `ConfigReader.normalizePlatforms`,
  `IosUtils`).
- `test/services/` — services that take injected `FileSystem` /
  `ProcessRunner` (`FirebaseProjectService`).
- `test/fixtures/` — real input files used by parser tests
  (e.g. `runner.pbxproj`).
- `test/utils/mocks.dart` — `MockFileSystem` and `MockProcessRunner`
  used by the service tests.

## What's Covered

- **Models**: `FlavorConfig.fromYaml` (suffix normalization, optional vs
  required fields, nullable `firebaseProjectId`), `GlobalConfig.fromYaml`
  (defaults derived from `iosTarget`, partial iOS config).
- **Utilities**: `GradleParser` (Groovy + Kotlin DSL flavors,
  applicationId, namespace fallback), `IosProjectParser`
  (pbxproj graph traversal, app name extraction), `YamlGenerator`
  (content shape, suffix inference, target-derived defaults),
  `YamlUpdater` (yaml_edit-driven, comment preservation),
  `ConfigReader.normalizePlatforms`, `IosUtils.configBaseRelativeToProjectDir`.
- **Services**: `FirebaseProjectService` (google-services.json parsing,
  GoogleService-Info.plist parsing, `detectFromConfigFiles` Android-vs-iOS
  preference, `listProjects` Firebase CLI JSON parsing).

## Intentionally Not Tested

- `init`, `configure`, `list`, `set-project-ids` command bodies
  themselves: high mocking surface (file system, processes, prerequisites,
  user input) for thin orchestration around already-tested utilities.
  Bug surface is in the utilities, which have unit coverage.
- `ios_run_script.dart`'s embedded Ruby/bash script: the generated
  shell is exercised at Xcode build time, not in Dart unit tests.

## Adding New Tests

- Pure functions: drop them in `test/<package>/<file>_test.dart` next to
  the existing tests.
- Anything that touches the file system or external processes: use the
  abstractions in `bin/src/utils/file_system.dart` and
  `bin/src/utils/process_runner.dart` and the mocks in
  `test/utils/mocks.dart`. Do not call real `dart:io` from tests.
- For pbxproj/Info.plist parsing edge cases, prefer adding to
  `test/fixtures/` over hand-writing minimal pbxproj strings — the
  format is unforgiving.
