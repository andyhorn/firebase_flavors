# Firebase Flavors

A Dart CLI tool for configuring Firebase for multiple Flutter flavors.

## Features

* Configures Firebase within your Flutter app for multiple flavors
  * Registers apps in Firebase project
  * Downloads Google config to flavor-based directories in Android and/or iOS dir
  * Generates per-flavor `firebase_options` file
  * Adds script to Xcode project to copy the correct `GoogleServices-Info.plist` file into build dir
* Initialize with your current settings from Android and/or iOS project files
* Customize package names, bundle IDs, output paths, and more

## Installation

### Global (Recommended)

```bash
dart pub global activate firebase_flavors
```

You can then run it from anywhere with:

```bash
dart run firebase_flavors [command]
```

Make sure your `PATH` includes the pub cache bin directory:
- **macOS/Linux**: `~/.pub-cache/bin`
- **Windows**: `%APPDATA%\Pub\Cache\bin`

### Local Development Dependency

Add this to your project's `pubspec.yaml` under `dev_dependencies`:

```bash
dart pub add dev:firebase_flavors
```

You can then run it from your project root with:

```bash
dart run firebase_flavors:firebase_flavors [command]
```

## Prerequisites

Before using `firebase_flavors`, ensure you have the following installed:

1. **FlutterFire CLI**: Required for Firebase configuration
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Ruby** (for iOS configuration): Required for Xcode project manipulation
   - macOS: Usually pre-installed
   - Linux/Windows: [Install Ruby](https://www.ruby-lang.org/en/documentation/installation/)

3. **xcodeproj gem** (for iOS configuration): Required for modifying Xcode projects
   ```bash
   gem install xcodeproj
   ```

4. **Flutter**: Your Flutter project should be set up with flavors configured in your `build.gradle` (Android) or Xcode schemes (iOS)

## Quick Start

### 1. Initialize Configuration

Run the init command in your Flutter project root:

```bash
firebase_flavors init
```

This command will:
- Detect your app's flavors from Android Gradle files or iOS project files
- Detect your base bundle ID and app name
- Generate a `firebase_flavors.yaml` configuration file

### 2. Set Firebase Project IDs

You can set Firebase project IDs in two ways:

**Option A: Use the `set-project-ids` command (Recommended)**

This command provides multiple methods to set project IDs:

```bash
# Auto-detect from existing config files
firebase_flavors set-project-ids --from-files

# Interactive selection from Firebase CLI projects list
firebase_flavors set-project-ids --from-firebase

# Interactive prompts
firebase_flavors set-project-ids --interactive

# Or specify directly via command line
firebase_flavors set-project-ids --project-ids dev:your-dev-project-id,prod:your-prod-project-id
```

**Option B: Edit Configuration Manually**

Open `firebase_flavors.yaml` and update the Firebase project IDs for each flavor:

```yaml
flavors:
  dev:
    firebaseProjectId: your-dev-project-id
    # ... other settings
  staging:
    firebaseProjectId: your-staging-project-id
    # ... other settings
  prod:
    firebaseProjectId: your-prod-project-id
    # ... other settings
```

### 3. Configure Firebase

Run the configure command to set up Firebase for your flavors:

```bash
firebase_flavors configure
```

This will configure all flavors, or you can specify flavors using a list:

```bash
firebase_flavors configure dev,staging
```

## Commands

### `init`

Initializes a new `firebase_flavors.yaml` configuration file.

```bash
firebase_flavors init [--force] [--config <path>]
```

**Options:**
- `--force`: Overwrite existing configuration file
- `--config <path>`: Specify custom config file path (default: `firebase_flavors.yaml`)

**What it does:**
- Detects flavors from `android/app/build.gradle` or iOS project files
- Detects base bundle ID from Android or iOS configuration
- Detects app name from project files
- Generates a YAML configuration file with detected values

### `configure`

Configures Firebase for specified flavors.

```bash
firebase_flavors configure [flavor1,flavor2,...] [--skip-firebase] [--skip-xcode] [--config <path>]
```

**Arguments:**
- `flavor1,flavor2,...`: Comma-separated list of flavors to configure (optional, defaults to all flavors)

**Options:**
- `--skip-firebase`: Skip Firebase configuration (only set up Xcode scripts)
- `--skip-xcode`: Skip Xcode run script setup (only configure Firebase)
- `--config <path>`: Specify custom config file path (default: `firebase_flavors.yaml`)

**What it does:**
- Runs `flutterfire configure` for each flavor
- Downloads and places `google-services.json` files for Android
- Downloads and places `GoogleService-Info.plist` files for iOS
- Sets up Xcode run scripts to copy the correct iOS config file based on build configuration
- Generates Dart options files (`firebase_options_*.dart`) for each flavor

### `list`

Lists all configured flavors and their details.

```bash
firebase_flavors list [--config <path>]
```

**Options:**
- `--config <path>`: Specify custom config file path (default: `firebase_flavors.yaml`)

**What it shows:**
- App name and base bundle ID
- Platform paths (Android source base, iOS Xcode project, etc.)
- For each flavor:
  - Firebase project ID
  - Supported platforms
  - Android package name and config file path
  - iOS bundle ID and config file path
  - Dart options output path

### `set-project-ids`

Sets Firebase project IDs for flavors in the configuration file.

```bash
firebase_flavors set-project-ids [--from-files] [--from-firebase] [--interactive] [--project-ids <pairs>] [--config <path>]
```

**Options:**
- `--from-files`: Auto-detect project IDs from existing `google-services.json` or `GoogleService-Info.plist` files
- `--from-firebase`: Interactive selection from Firebase CLI projects list (requires Firebase CLI login)
- `--interactive`: Prompt for project IDs interactively
- `--project-ids <pairs>`: Comma-separated list of `flavor:project-id` pairs (e.g., `dev:project-id-1,prod:project-id-2`)
- `--config <path>`: Specify custom config file path (default: `firebase_flavors.yaml`)

**What it does:**
- Updates the `firebaseProjectId` field for each flavor in `firebase_flavors.yaml`
- Supports multiple methods for setting project IDs:
  - Auto-detection from existing config files
  - Interactive selection from Firebase projects
  - Interactive prompts
  - Direct specification via command line
- If no method is specified, defaults to interactive mode

### Global Options

All commands support these global options:

- `--help, -h`: Show help information
- `--verbose, -v`: Show additional debug output
- `--version`: Show tool version
- `--config <path>, -c`: Specify custom config file path (default: `firebase_flavors.yaml`)

## Configuration File Structure

The `firebase_flavors.yaml` file has the following structure:

```yaml
# App-level configuration (required)
appName: MyApp
baseBundleId: com.example.app

# Android configuration (optional - all fields have defaults)
android:
  srcBase: android/app/src  # Optional, default: android/app/src

# iOS configuration (optional - all fields have defaults)
ios:
  xcodeprojPath: ios/Runner.xcodeproj  # Optional, default: ios/Runner.xcodeproj
  target: Runner  # Optional, default: Runner
  configBase: ios/Runner/Runner  # Optional, default: ios/Runner/Runner

# Flavor-specific configuration
flavors:
  dev:
    firebaseProjectId: my-dev-project-id  # Required
    androidPackageSuffix: .dev  # Optional, default: null (no suffix)
    dartOptionsOut: lib/firebase_options_dev.dart  # Optional, default: lib/firebase_options_{flavor}.dart
    androidSrcDir: dev  # Optional, default: {flavor}
    iosConfigDir: dev  # Optional, default: {flavor}
    platforms: android,ios  # Optional, default: null (all platforms)
    iosBundleId: com.example.app.dev  # Optional, default: null (uses baseBundleId)
  
  prod:
    firebaseProjectId: my-prod-project-id  # Required
    androidPackageSuffix: ""  # Optional, empty string = no suffix (default: null)
    # All other fields are optional with defaults as shown above
```

### Configuration Fields

#### Global Configuration

- `appName` (required): Your app's display name
- `baseBundleId` (required): Base bundle/package identifier (e.g., `com.example.app`)

#### Android Configuration (all optional)

- `android.srcBase` (optional): Base directory for Android source files. Default: `android/app/src`

#### iOS Configuration (all optional)

- `ios.xcodeprojPath` (optional): Path to your Xcode project file. Default: `ios/Runner.xcodeproj`
- `ios.target` (optional): Xcode target name. Default: `Runner`
- `ios.configBase` (optional): Base directory for iOS configuration files. Default: `ios/Runner/Runner`

#### Flavor Configuration

- `firebaseProjectId` (required): Your Firebase project ID for this flavor
- `androidPackageSuffix` (optional): Suffix to append to base bundle ID for Android (e.g., `.dev`, `.staging`). Default: `null` (no suffix). If provided without a leading dot, one will be added automatically
- `dartOptionsOut` (optional): Path where the Dart options file will be generated. Default: `lib/firebase_options_{flavor}.dart`
- `androidSrcDir` (optional): Directory name under `android/srcBase` where `google-services.json` will be placed. Default: `{flavor}` (the flavor name)
- `iosConfigDir` (optional): Directory name under `ios.configBase` where `GoogleService-Info.plist` will be placed. Default: `{flavor}` (the flavor name)
- `platforms` (optional): Comma-separated list of platforms (`android`, `ios`). If omitted or empty, all platforms are configured. Default: `null` (all platforms)
- `iosBundleId` (optional): Override iOS bundle ID for this flavor. If omitted or empty, uses `baseBundleId`. Default: `null` (uses `baseBundleId`)

## Examples

### Example 1: Basic Setup

```bash
# 1. Initialize
firebase_flavors init

# 2. Set Firebase project IDs (or edit firebase_flavors.yaml manually)
firebase_flavors set-project-ids --from-firebase

# 3. Configure all flavors
firebase_flavors configure
```

### Example 2: Configure Specific Flavors

```bash
# Configure only dev and staging
firebase_flavors configure dev,staging
```

### Example 3: Skip Xcode Setup

```bash
# Configure Firebase but skip Xcode run script setup
firebase_flavors configure --skip-xcode
```

### Example 4: Custom Config File

```bash
# Use a custom configuration file
firebase_flavors init --config custom_config.yaml
firebase_flavors configure --config custom_config.yaml
```

### Example 5: Verbose Output

```bash
# Get detailed debug information
firebase_flavors configure --verbose
```

### Example 6: Set Project IDs from Files

```bash
# Auto-detect project IDs from existing config files
firebase_flavors set-project-ids --from-files
```

### Example 7: Set Project IDs from Firebase CLI

```bash
# Select projects interactively from Firebase CLI
firebase_flavors set-project-ids --from-firebase
```

### Example 8: Set Project IDs via Command Line

```bash
# Set project IDs directly
firebase_flavors set-project-ids --project-ids dev:my-dev-project,staging:my-staging-project,prod:my-prod-project
```

## Project Structure

After configuration, your project structure will look like this:

```
your_flutter_project/
├── firebase_flavors.yaml
├── lib/
│   ├── firebase_options_dev.dart
│   ├── firebase_options_staging.dart
│   └── firebase_options_prod.dart
├── android/
│   └── app/
│       └── src/
│           ├── dev/
│           │   └── google-services.json
│           ├── staging/
│           │   └── google-services.json
│           └── prod/
│               └── google-services.json
└── ios/
    └── Runner/
        └── Runner/
            ├── dev/
            │   └── GoogleService-Info.plist
            ├── staging/
            │   └── GoogleService-Info.plist
            └── prod/
                └── GoogleService-Info.plist
```

## Using in Your Flutter App

After configuration, use separate Dart entrypoints for each flavor, as recommended by Firebase. This allows you to specify which `firebase_options_x.dart` file to include per flavor, without needing conditional imports or extra build tools.

For example, create separate files in your `lib/` directory:

<details>
<summary><code>lib/main_dev.dart</code></summary>

```dart
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```
</details>

<details>
<summary><code>lib/main_staging.dart</code></summary>

```dart
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_staging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```
</details>

<details>
<summary><code>lib/main_prod.dart</code></summary>

```dart
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_prod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```
</details>

<br/>

To run a specific flavor, provide the corresponding entrypoint with Flutter's `-t` (target) flag:

```bash
# Development flavor
flutter run -t lib/main_dev.dart

# Staging flavor
flutter run -t lib/main_staging.dart

# Production flavor
flutter run -t lib/main_prod.dart
```

> **Tip:** This is the recommended approach for multi-flavor support. Each entrypoint statically imports the correct `firebase_options_*.dart` file for its flavor, avoiding runtime ambiguity and making builds more robust and predictable.


## Troubleshooting

### flutterfire CLI not found

**Error**: `flutterfire CLI is not installed or not found on your PATH`

**Solution**:
```bash
dart pub global activate flutterfire_cli
# Make sure ~/.pub-cache/bin is in your PATH
```

### xcodeproj gem not found

**Error**: `xcodeproj gem is not installed`

**Solution**:
```bash
gem install xcodeproj
```

### Configuration file not detected

**Error**: `No project configuration detected, using defaults`

**Solution**: The tool will use default values. You can manually edit `firebase_flavors.yaml` after initialization to match your project structure.

### Firebase project ID not set

**Error**: `firebaseProjectId is required`

**Solution**: Make sure each flavor in `firebase_flavors.yaml` has a valid `firebaseProjectId` set.

### Xcode script setup fails

**Error**: Issues with Xcode run script setup

**Solution**: 
- Ensure Ruby and xcodeproj gem are installed
- Check that your Xcode project path is correct in the configuration
- Try running with `--skip-xcode` to skip this step and set up manually

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source. Please check the repository for license information.

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/andyhorn/firebase_flavors).
