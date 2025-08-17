# CI/CD Documentation

This document describes the continuous integration and deployment setup for StoryPad.

## Overview

StoryPad uses GitHub Actions for automated testing, building, and deployment. The CI/CD pipeline ensures code quality, runs comprehensive tests, and provides automated builds for different app flavors.

## Workflows

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Triggers:** Pull requests and pushes to `main` and `develop` branches

**Steps:**
- Sets up Java 21 and Flutter 3.35.1-stable
- Installs dependencies with `flutter pub get`
- Generates code with `dart run build_runner build`
- Verifies code formatting with `dart format`
- Runs static analysis with `flutter analyze`
- Executes tests with coverage reporting
- Uploads coverage to Codecov

### 2. Build Workflow (`.github/workflows/build.yml`)

**Triggers:** Pushes to `main`, tag creation, manual dispatch

**Features:**
- Builds Android APK and App Bundle for selected flavors
- Supports manual flavor selection via workflow dispatch
- Builds iOS on macOS for tagged releases
- Uploads build artifacts for download

**Supported Flavors:**
- `community` (default, open source)
- `storypad` (main app)
- `spooky` (themed variant)

### 3. Dependencies & Security (`.github/workflows/dependencies.yml`)

**Triggers:** Weekly schedule (Mondays), manual dispatch

**Actions:**
- Checks for outdated packages
- Analyzes pub.dev scores for dependencies
- Performs security audit and analysis
- Reports potential security issues

### 4. Release Workflow (`.github/workflows/release.yml`)

**Triggers:** Git tag creation, manual dispatch

**Process:**
- Creates GitHub release from tag
- Builds release assets (APK and App Bundle)
- Attaches build artifacts to release
- Supports manual release creation

## Tool Requirements

The workflows are configured to use exact versions specified in `.tool-versions`:

- **Java:** 21 (Temurin distribution)
- **Ruby:** 3.3.5 (for iOS/CocoaPods)
- **Flutter:** 3.35.1-stable

## Caching

Flutter and Dart dependencies are cached to improve build performance:
- Flutter SDK cache
- Pub dependency cache
- Generated code cache

## Artifacts

Build workflows generate the following artifacts:

- **APK files:** `build/app/outputs/flutter-apk/*.apk`
- **App Bundle files:** `build/app/outputs/bundle/**/*.aab`
- **iOS IPA files:** `build/ios/ipa/*.ipa` (macOS only)

## Security

- Dependency security scanning
- Code analysis for security issues
- Automated reporting of vulnerabilities
- Weekly dependency updates checking

## Development Integration

### Local Development

Use the provided scripts for consistency with CI:

```bash
# Development server
bin/dev --community

# Build commands (matches CI)
bin/build_apk --community
bin/build_appbundle --community

# Testing and analysis
flutter test
flutter analyze
dart format .
```

### Pull Request Workflow

1. Create feature branch
2. Make changes with tests
3. Push to GitHub
4. CI automatically runs tests and analysis
5. Review and merge after CI passes

### Release Process

1. Update version in `pubspec.yaml`
2. Create and push git tag: `git tag v2.16.2 && git push origin v2.16.2`
3. Release workflow automatically creates GitHub release with assets

## Troubleshooting

### Common Issues

1. **Build failures:** Check Java 21 requirement
2. **Test failures:** Ensure `flutter pub get` and `build_runner build` completed
3. **iOS builds:** Only available on macOS runners for tagged releases
4. **Artifact uploads:** Check file paths match expected outputs

### Monitoring

- Check workflow status in GitHub Actions tab
- Review build logs for detailed error information
- Monitor dependency security reports weekly