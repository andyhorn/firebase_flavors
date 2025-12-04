#!/bin/bash
# Extract version from pubspec.yaml
# Usage: ./scripts/get_version.sh

grep -E '^version:' pubspec.yaml | sed -E 's/^version: //' | sed -E 's/\+.*$//'

