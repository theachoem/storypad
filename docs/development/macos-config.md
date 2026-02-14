# macOS Configuration

**macOS-specific configuration and setup.**

## Podfile

Location: `macos/Podfile`

### Deployment Target

The minimum deployment target is set to macOS 11.0 in the Podfile:

```ruby
platform :osx, '11.0'
```

### CocoaPods Deployment Target Fix

After updating Flutter, CocoaPods dependencies may have outdated deployment targets (10.11, 10.12) that are below the minimum supported version (10.13) for current Xcode versions. The `post_install` hook ensures all pods use at least 10.13:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)
    
    # Set minimum deployment target to 10.13 for all pods
    target.build_configurations.each do |config|
      if config.build_settings['MACOSX_DEPLOYMENT_TARGET'].to_f < 10.13
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.13'
      end
    end
  end
end
```

This prevents build warnings like:
```
warning: The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 10.12, 
but the range of supported deployment target versions is 10.13 to 26.2.99.
```

## Build Commands

```bash
# Development
bin/dev --storypad-macos

# Using flutter directly
flutter run --target=lib/main_storypad.dart --flavor storypad \
  --dart-define-from-file=private_keys/dart_defines/storypad.json \
  --dart-define=CUPERTINO=yes -d macos
```

## Common Issues

### Deployment Target Warnings

**Problem:** After Flutter update, build shows warnings about MACOSX_DEPLOYMENT_TARGET being too old.

**Solution:** The Podfile's `post_install` hook automatically fixes this. If issues persist:

1. Clean the project:
   ```bash
   flutter clean
   ```

2. Remove Pods and reinstall:
   ```bash
   cd macos
   rm -rf Pods Podfile.lock
   pod repo update
   pod install
   cd ..
   ```

3. Clean Xcode derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
   ```

4. Try building again:
   ```bash
   bin/dev --storypad-macos
   ```

### Build Fails

- Check Xcode version compatibility with Flutter version
- Verify CocoaPods is up to date: `pod --version`
- Clean build: `flutter clean && flutter pub get`
- Check that Firebase configuration is correct if using FlutterFire

## See Also

- [iOS Config](ios-config.md) - iOS-specific configuration
- [Android Config](android-config.md) - Android-specific configuration
