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
