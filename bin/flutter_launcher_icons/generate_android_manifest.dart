// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    print('Error: Missing required arguments');
    print('Usage: dart generate_android_manifest.dart <FLAVOR> <ICON_NAME>');
    print('Example: dart generate_android_manifest.dart storypad storypad_logo_1_0');
    exit(1);
  }

  final flavor = args[0];
  final iconName = args[1];

  // Get package name from main AndroidManifest.xml
  final packageName = _getPackageName();

  // Get all available logos
  final logos = _getAvailableLogos();

  if (logos.isEmpty) {
    print('Error: No logos found in assets/logos/');
    exit(1);
  }

  print('Found ${logos.length} logos: ${logos.join(', ')}');

  // Validate that the selected icon exists
  if (!logos.contains(iconName)) {
    print('Error: Icon "$iconName" not found in assets/logos/');
    print('Available logos: ${logos.join(', ')}');
    exit(1);
  }

  // Generate AndroidManifest.xml
  final manifestPath = 'android/app/src/$flavor/AndroidManifest.xml';
  final manifestDir = Directory('android/app/src/$flavor');

  if (!manifestDir.existsSync()) {
    manifestDir.createSync(recursive: true);
  }

  final manifestContent = _generateManifest(packageName, logos, logos[0]);

  File(manifestPath).writeAsStringSync(manifestContent);

  print('✅ Updated $manifestPath');
  print('   Generated ${logos.length} activity-alias entries');
  print('   Enabled icon: $iconName');
}

/// Get package name from main AndroidManifest.xml
String _getPackageName() {
  final mainManifestFile = File('android/app/src/main/AndroidManifest.xml');

  if (!mainManifestFile.existsSync()) {
    print('Warning: Could not find main AndroidManifest.xml, using default package name');
    return 'com.tc.writestory';
  }

  final content = mainManifestFile.readAsStringSync();
  final packageRegex = RegExp(r'package="([^"]+)"');
  final match = packageRegex.firstMatch(content);

  if (match != null) {
    return match.group(1)!;
  }

  // Fallback: extract from MainActivity reference
  final activityRegex = RegExp(r'android:name="([^"]+)\.MainActivity"');
  final activityMatch = activityRegex.firstMatch(content);

  if (activityMatch != null) {
    return activityMatch.group(1)!;
  }

  print('Warning: Could not extract package name, using default');
  return 'com.tc.writestory';
}

/// Get all available logos from assets/logos directory
List<String> _getAvailableLogos() {
  final logosDir = Directory('assets/logos');

  if (!logosDir.existsSync()) {
    return [];
  }

  final logos = <String>[];

  for (final entity in logosDir.listSync()) {
    if (entity is Directory && entity.path.endsWith('.icon')) {
      final logoName = entity.path.split('/').last.replaceAll('.icon', '');
      logos.add(logoName);
    }
  }

  // Sort for consistent ordering
  logos.sort();

  return logos;
}

/// Generate AndroidManifest.xml content with all activity-alias entries
String _generateManifest(String packageName, List<String> logos, String enabledIcon) {
  final aliases = <String>[];

  for (final logo in logos) {
    final enabled = logo == enabledIcon ? 'true' : 'false';

    aliases.add('''        <!-- App logo alias for $logo -->
        <activity-alias
            android:name="$packageName.$logo"
            android:targetActivity="$packageName.MainActivity"
            android:icon="@mipmap/$logo"
            android:enabled="$enabled"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity-alias>''');
  }

  return '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
${aliases.join('\n\n')}
    </application>
</manifest>''';
}
