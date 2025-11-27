// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('\n🔍 Scanning for unused translation keys...\n');

  // Keys that are intentionally unused or reserved for future use
  const exceptionalUnusedKeys = {
    '_fomula',
    'button.maybe_later',
    'dialog.lookings_back.subtitle.other',
  };

  // Load en.json
  final enJsonFile = File('translations/en.json');
  final enJsonContent = await enJsonFile.readAsString();
  final Map<String, dynamic> enJson = jsonDecode(enJsonContent);

  // Get all keys from en.json (excluding meta keys)
  final List<String> allKeys = enJson.keys.where((key) => !key.startsWith('_meta.')).toList()..sort();

  print('=== Total Translation Keys: ${allKeys.length} ===\n');

  // Search in dart files
  final libDir = Directory('lib');
  final dartFiles = _getAllDartFiles(libDir);

  print('=== Searching in ${dartFiles.length} dart files ===\n');

  // Read all dart files content
  final allDartContent = StringBuffer();
  for (final file in dartFiles) {
    final content = await file.readAsString();
    allDartContent.write(content);
  }
  final dartContentStr = allDartContent.toString();

  // Find unused keys
  final unusedKeys = <String>[];
  for (final key in allKeys) {
    // Skip exceptional keys
    if (exceptionalUnusedKeys.contains(key)) {
      continue;
    }

    // For plural keys (e.g., plural.day_ago.one), check if base key exists (e.g., plural.day_ago)
    String keyToCheck = key;
    if (key.startsWith('plural.')) {
      final parts = key.split('.');
      if (parts.length == 3) {
        keyToCheck = '${parts[0]}.${parts[1]}'; // Remove .one or .other suffix
      }
    }

    if (!dartContentStr.contains("'$keyToCheck'") && !dartContentStr.contains('"$keyToCheck"')) {
      unusedKeys.add(key);
    }
  }

  // Print results
  print('----------------------------');
  if (unusedKeys.isEmpty) {
    print('✅ All keys are used!\n');
  } else {
    print('❌ Found ${unusedKeys.length} unused keys:\n');
    for (final key in unusedKeys) {
      print('  • $key');
    }
    print('\n');
  }
  print('----------------------------\n');

  // ============================================================================
  // REVERSE TEST: Find keys used in code but not in en.json
  // ============================================================================

  print('\n🔄 Scanning for missing translation keys in en.json...\n');

  // Extract all translation keys used in code (tr('key') or plural('key'))
  final usedKeysInCode = _extractTranslationKeysFromCode(dartContentStr);

  print('=== Found ${usedKeysInCode.length} translation keys used in code ===\n');

  // Find keys used in code but not in en.json
  final missingKeys = <String>[];
  for (final key in usedKeysInCode) {
    bool keyExists = false;

    if (key.startsWith('plural.')) {
      // For keys that start with 'plural.', check if any key starts with this base
      keyExists = enJson.keys.any((jsonKey) => jsonKey.startsWith('$key.'));
    } else {
      // For regular keys and plural base keys used with plural() function,
      // check if the key exists OR if plural variants exist (key.one, key.other)
      keyExists = enJson.containsKey(key) || enJson.containsKey('$key.one') || enJson.containsKey('$key.other');
    }

    if (!keyExists) {
      missingKeys.add(key);
    }
  }

  // Print results
  print('----------------------------');
  if (missingKeys.isEmpty) {
    print('✅ All used keys exist in en.json!\n');
  } else {
    print('❌ Found ${missingKeys.length} keys used in code but missing in en.json:\n');
    for (final key in missingKeys) {
      print('  • $key');
    }
    print('\n');
  }
  print('----------------------------\n');
}

/// Get all .dart files recursively
List<File> _getAllDartFiles(Directory dir) {
  final dartFiles = <File>[];

  try {
    final entities = dir.listSync(recursive: false);
    for (final entity in entities) {
      if (entity is Directory) {
        // Skip common directories
        if (!_shouldSkipDirectory(entity.path)) {
          dartFiles.addAll(_getAllDartFiles(entity));
        }
      } else if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }
  } catch (e) {
    print('Error reading directory: $e');
  }

  return dartFiles;
}

/// Check if directory should be skipped
bool _shouldSkipDirectory(String path) {
  final shouldSkip = [
    'generated',
    'packages',
    '.dart_tool',
    'build',
  ];

  for (final skip in shouldSkip) {
    if (path.contains('/$skip/') || path.endsWith('/$skip')) {
      return true;
    }
  }

  return false;
}

/// Extract all translation keys used in code via tr() or plural()
Set<String> _extractTranslationKeysFromCode(String dartContent) {
  final keys = <String>{};

  // Pattern 1: tr('key', ...) or tr("key", ...)
  // This matches tr('key') or tr('key', context: context) or any parameters
  final trPatternSingle = RegExp(r"tr\('([^']+)'(?:\s*,|\s*\))");
  for (final match in trPatternSingle.allMatches(dartContent)) {
    keys.add(match.group(1)!);
  }

  final trPatternDouble = RegExp(r'tr\("([^"]+)"(?:\s*,|\s*\))');
  for (final match in trPatternDouble.allMatches(dartContent)) {
    keys.add(match.group(1)!);
  }

  // Pattern 2: plural('key', ...) or plural("key", ...)
  final pluralPatternSingle = RegExp(r"plural\('([^']+)'(?:\s*,|\s*\))");
  for (final match in pluralPatternSingle.allMatches(dartContent)) {
    keys.add(match.group(1)!);
  }

  final pluralPatternDouble = RegExp(r'plural\("([^"]+)"(?:\s*,|\s*\))');
  for (final match in pluralPatternDouble.allMatches(dartContent)) {
    keys.add(match.group(1)!);
  }

  return keys;
}
