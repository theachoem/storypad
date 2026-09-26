import 'dart:convert';
import 'dart:io';

/// Real-shape Quill fixtures (anonymized structural copies of production stories), keyed by name.
Map<String, List<Object?>> loadQuillFixtures() {
  final files =
      Directory('test/fixtures/quill').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final file in files)
      file.uri.pathSegments.last.replaceAll('.json', ''): jsonDecode(file.readAsStringSync()) as List<Object?>,
  };
}

File markdownGolden(String name) => File('test/fixtures/markdown/$name.md');

/// Set `UPDATE_GOLDENS=1` to rewrite the Markdown goldens from the current output.
bool get updateGoldens => Platform.environment['UPDATE_GOLDENS'] == '1';
