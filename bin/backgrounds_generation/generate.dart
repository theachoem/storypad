// ignore_for_file: avoid_print

// This script processes background images from firestore_storages/story_backgrounds
// and generates Dart code in lib/gen/story_backgrounds.dart
// To run, use:
// ```
// dart bin/backgrounds_generation/generate.dart
// ```

import 'dart:io';

void main() async {
  print('Starting story backgrounds generation...');

  final backgroundsDir = Directory('firestore_storages/story_backgrounds');

  if (!await backgroundsDir.exists()) {
    print('Error: Directory firestore_storages/story_backgrounds not found');
    exit(1);
  }

  // Get all image files
  final files = await backgroundsDir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.jpg'))
      .cast<File>()
      .toList();

  if (files.isEmpty) {
    print('No background images found');
    return;
  }

  // Group files by category
  final Map<String, List<BackgroundInfo>> groupedBackgrounds = {};

  for (final file in files) {
    final filename = file.uri.pathSegments.last;
    final info = _parseFilename(filename);

    if (info == null) {
      print('Warning: Skipping invalid filename: $filename');
      continue;
    }

    groupedBackgrounds.putIfAbsent(info.group, () => []).add(info);
  }

  // Generate Dart code
  final dartContent = _generateDartCode(groupedBackgrounds);
  final outputFile = File('lib/gen/story_backgrounds.dart');

  // Ensure directory exists
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(dartContent);

  final totalBackgrounds = groupedBackgrounds.values.fold<int>(0, (sum, list) => sum + list.length);

  print('Generated: ${outputFile.path}');
  print('  - ${groupedBackgrounds.length} groups');
  print('  - $totalBackgrounds backgrounds');

  // Format the generated file
  print('\nFormatting...');
  final formatResult = await Process.run('dart', [
    'format',
    '--line-length=120',
    outputFile.path,
  ]);

  if (formatResult.exitCode == 0) {
    print('Formatted successfully');
  } else {
    print('Warning: Formatting failed');
    print(formatResult.stderr);
  }

  print('\nCompleted!');
}

BackgroundInfo? _parseFilename(String filename) {
  // Remove extension
  final nameWithoutExt = filename.replaceAll('.jpg', '');

  // Split by double underscore
  final parts = nameWithoutExt.split('__');

  if (parts.length != 4) {
    return null;
  }

  final group = parts[0];
  final name = parts[1];
  final alignPart = parts[2]; // align-left, align-center, align-right
  final textPart = parts[3]; // text-black, text-white, text_white, etc.

  // Extract align value
  String align;
  if (alignPart.startsWith('align-')) {
    align = alignPart.substring(6); // Remove 'align-'
  } else {
    return null;
  }

  // Extract text color value (handle both dash and underscore)
  String textColor;
  if (textPart.startsWith('text-')) {
    textColor = textPart.substring(5); // Remove 'text-'
  } else if (textPart.startsWith('text_')) {
    textColor = textPart.substring(5); // Remove 'text_'
  } else {
    return null;
  }

  return BackgroundInfo(
    group: group,
    name: name,
    align: align,
    textColor: textColor,
    filename: filename,
  );
}

String _generateDartCode(Map<String, List<BackgroundInfo>> groupedBackgrounds) {
  final buffer = StringBuffer();

  // Header
  buffer.writeln('// dart format width=80');
  buffer.writeln();
  buffer.writeln('/// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('/// *****************************************************');
  buffer.writeln('///  Story Backgrounds Generator');
  buffer.writeln('/// *****************************************************');
  buffer.writeln();
  buffer.writeln('// coverage:ignore-file');
  buffer.writeln('// ignore_for_file: type=lint');
  buffer.writeln();

  // Enums
  buffer.writeln('enum StoryBackgroundAlign {');
  buffer.writeln('  left,');
  buffer.writeln('  center,');
  buffer.writeln('  right,');
  buffer.writeln('}');
  buffer.writeln();

  buffer.writeln('enum StoryBackgroundTextColor {');
  buffer.writeln('  black,');
  buffer.writeln('  white,');
  buffer.writeln('}');
  buffer.writeln();

  // Model class
  buffer.writeln('class StoryBackground {');
  buffer.writeln('  final String name;');
  buffer.writeln('  final String path;');
  buffer.writeln('  final StoryBackgroundAlign align;');
  buffer.writeln('  final StoryBackgroundTextColor textColor;');
  buffer.writeln();
  buffer.writeln('  const StoryBackground({');
  buffer.writeln('    required this.name,');
  buffer.writeln('    required this.path,');
  buffer.writeln('    required this.align,');
  buffer.writeln('    required this.textColor,');
  buffer.writeln('  });');
  buffer.writeln('}');
  buffer.writeln();

  // Main class
  buffer.writeln('class StoryBackgrounds {');
  buffer.writeln('  const StoryBackgrounds._();');
  buffer.writeln();

  // Generate static lists for each group
  for (final entry in groupedBackgrounds.entries) {
    final group = entry.key;
    final backgrounds = entry.value;
    final camelCaseGroup = _toCamelCase(group);

    buffer.writeln('  static const $camelCaseGroup = [');
    for (final bg in backgrounds) {
      buffer.writeln('    StoryBackground(');
      buffer.writeln('      name: \'${bg.name}\',');
      buffer.writeln('      path: \'/story_backgrounds/${bg.filename}\',');
      buffer.writeln('      align: .${bg.align},');
      buffer.writeln('      textColor: .${bg.textColor},');
      buffer.writeln('    ),');
    }
    buffer.writeln('  ];');
    buffer.writeln();
  }

  // Generate all map
  buffer.writeln('  static const all = <String, List<StoryBackground>>{');
  for (final group in groupedBackgrounds.keys) {
    final camelCaseGroup = _toCamelCase(group);
    buffer.writeln('    \'$group\': $camelCaseGroup,');
  }
  buffer.writeln('  };');
  buffer.writeln();

  // Generate byFilename map
  buffer.writeln('  static final byFilename = <String, StoryBackground>{');
  for (final entry in groupedBackgrounds.entries) {
    final group = entry.key;
    final backgrounds = entry.value;
    final camelCaseGroup = _toCamelCase(group);

    for (var i = 0; i < backgrounds.length; i++) {
      final bg = backgrounds[i];
      buffer.writeln('    \'${bg.filename}\': $camelCaseGroup[$i],');
    }
  }
  buffer.writeln('  };');
  buffer.writeln();

  // Generate groups list
  buffer.writeln('  static const groups = [');
  for (final group in groupedBackgrounds.keys) {
    buffer.writeln('    \'$group\',');
  }
  buffer.writeln('  ];');

  buffer.writeln('}');

  return buffer.toString();
}

String _toCamelCase(String text) {
  if (text.isEmpty) return text;

  final parts = text.split('_');
  if (parts.length == 1 && !text.contains('-')) {
    return text;
  }

  return parts
      .asMap()
      .entries
      .map((entry) {
        if (entry.key == 0) return entry.value;
        return entry.value[0].toUpperCase() + entry.value.substring(1);
      })
      .join('');
}

class BackgroundInfo {
  final String group;
  final String name;
  final String align;
  final String textColor;
  final String filename;

  BackgroundInfo({
    required this.group,
    required this.name,
    required this.align,
    required this.textColor,
    required this.filename,
  });
}
