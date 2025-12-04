# Testing Notes

## Currently Testable

✅ **Models** (`test/models/`):
- `GlobalConfig.fromYaml()` - YAML parsing
- `FlavorConfig.fromYaml()` - YAML parsing with normalization

✅ **Utilities** (`test/utils/`):
- `ConfigReader.normalizePlatforms()` - Platform name normalization

## Not Easily Unit Testable (Requires Refactoring)

### Commands (`configure`, `init`, `list`)
These are hard to unit test because they:
- Call `exit()` which terminates the process
- Interact with the file system (need mocking)
- Call external processes (flutterfire, ruby) - need process mocking
- Have side effects (file creation, process execution)

**Recommendation**: Use integration tests or extract testable logic.

### Private Parsing Functions in `init.dart`
These functions are private and would need to be extracted:

- `_extractApplicationId()` - Gradle bundle ID parsing
- `_extractProductFlavors()` - Gradle flavor parsing (KTS & Groovy)
- `_extractAppNameFromGradle()` - App name extraction
- `_generateYamlContent()` - YAML generation
- `_inferFlavorsFromBuildConfigs()` - iOS build config parsing

**Recommendation**: Extract to `bin/src/utils/gradle_parser.dart` and `bin/src/utils/yaml_generator.dart`

### Private Functions in `ios_run_script.dart`
- `_configBaseRelativeToProjectDir()` - Path normalization
- `_rubyScriptContents()` - Ruby script generation

**Recommendation**: Make these `internal` or extract to a testable utility.

## Suggested Refactoring for Better Testability

1. **Extract Gradle Parsing**:
   ```dart
   // bin/src/utils/gradle_parser.dart
   class GradleParser {
     static String? extractApplicationId(String content);
     static Map<String, String> extractProductFlavors(String content, bool isKts);
     static String? extractAppName(String content);
   }
   ```

2. **Extract YAML Generation**:
   ```dart
   // bin/src/utils/yaml_generator.dart
   class YamlGenerator {
     static String generateContent({...});
   }
   ```

3. **Extract iOS Utilities**:
   ```dart
   // bin/src/utils/ios_utils.dart
   class IosUtils {
     static String configBaseRelativeToProjectDir(String configBase);
     static String rubyScriptContents();
   }
   ```

4. **Make Commands Testable**:
   - Use dependency injection for file system operations
   - Use process mocking for external commands
   - Extract business logic from command handlers

## Integration Testing

For full command testing, consider integration tests that:
- Use temporary directories
- Mock external processes
- Verify file outputs
- Test end-to-end workflows

