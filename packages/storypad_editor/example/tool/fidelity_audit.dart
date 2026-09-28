import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

/// Checks how faithfully real stories survive the editor's bridge path -- Quill (as stored) → Markdown (as edited) →
/// Quill (as saved) -- without printing any story text: only counts, attribute keys/values, and story ids.
///
/// Reads StoryPad backups: a backup file (gzip-compressed or plain JSON), or a folder of them (yearly backups are one
/// file per year).

/// One page of Quill ops, with where it came from (ids only).
class AuditPage {
  const AuditPage(this.location, this.ops);

  final String location;
  final List<Object?> ops;
}

/// Every page in the backup(s) at [path]: stories (latest and draft content) and templates.
List<AuditPage> pagesFromBackups(String path) {
  final entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
      ? Directory(path).listSync(recursive: true).whereType<File>().toList()
      : [File(path)];
  entity.sort((a, b) => a.path.compareTo(b.path));

  final pages = <AuditPage>[];
  for (final file in entity) {
    final Object? contents;
    try {
      contents = _readJson(file);
    } on FormatException {
      stderr.writeln('Skipping ${file.path}: not a backup (neither JSON nor gzip-compressed JSON).');
      continue;
    }
    if (contents is! Map) continue;

    final tables = contents['tables'] is Map ? contents['tables'] as Map : contents;
    for (final story in _list(tables['stories'])) {
      if (story is! Map) continue;
      for (final key in ['latest_content', 'draft_content']) {
        pages.addAll(_contentPages(story[key], 'story ${story['id']} ${key.replaceAll('_content', '')}'));
      }
    }
    for (final template in _list(tables['templates'])) {
      if (template is! Map) continue;
      pages.addAll(_contentPages(template['content'], 'template ${template['id']}'));
    }
  }
  return pages;
}

Object? _readJson(File file) {
  final bytes = file.readAsBytesSync();
  final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
  return jsonDecode(utf8.decode(isGzip ? gzip.decode(bytes) : bytes));
}

List<Object?> _list(Object? value) => value is List ? value : const [];

Iterable<AuditPage> _contentPages(Object? content, String location) sync* {
  final map = content is String ? _tryDecode(content) : content;
  if (map is! Map) return;

  final richPages = map['rich_pages'];
  if (richPages is List) {
    for (final (index, page) in richPages.indexed) {
      if (page is Map && page['body'] is List) yield AuditPage('$location page $index', page['body'] as List);
    }
    return;
  }
  // Legacy content: `pages` is a list of op lists.
  for (final (index, ops) in _list(map['pages']).indexed) {
    if (ops is List) yield AuditPage('$location legacy page $index', ops);
  }
}

Object? _tryDecode(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}

/// The audit's findings.
class AuditReport {
  int pages = 0;
  int ops = 0;
  int failed = 0;

  /// Losses by `kind key=value`, with example locations.
  final losses = <String, List<String>>{};

  /// Pages whose round trip differs although no loss was reported (a bug in the converter or the loss finder).
  final unexpected = <String, String>{};

  /// Embed ops written back differently (a key or attribute normalized), by description.
  final embedRewrites = <String, List<String>>{};

  /// Embed keys no embed claims (kept verbatim), with counts.
  final unknownKeys = <String, int>{};

  /// Per-page conversion time (Quill → Markdown → Quill), in microseconds.
  final timings = <int>[];

  bool get isClean => losses.isEmpty && unexpected.isEmpty && failed == 0;

  String format() {
    final buffer = StringBuffer()
      ..writeln('Fidelity audit: $pages pages, $ops ops')
      ..writeln();

    buffer.writeln('Formatting the conversion drops: ${losses.isEmpty ? 'none' : ''}');
    for (final MapEntry(:key, :value) in _byCount(losses)) {
      buffer.writeln('  ${value.length}× $key   e.g. ${value.take(3).join('; ')}');
    }

    buffer.writeln('\nUnexpected round-trip differences (no loss reported): ${unexpected.isEmpty ? 'none' : ''}');
    for (final MapEntry(:key, :value) in unexpected.entries.take(50)) {
      buffer.writeln('  $key: $value');
    }
    if (unexpected.length > 50) buffer.writeln('  … ${unexpected.length - 50} more');

    buffer.writeln('\nPages that failed to convert: $failed');

    buffer.writeln('\nEmbed ops written back differently (same value): ${embedRewrites.isEmpty ? 'none' : ''}');
    for (final MapEntry(:key, :value) in _byCount(embedRewrites)) {
      buffer.writeln('  ${value.length}× $key   e.g. ${value.take(2).join('; ')}');
    }

    buffer.writeln('\nEmbed keys kept as unknown: ${unknownKeys.isEmpty ? 'none' : ''}');
    for (final MapEntry(:key, :value) in unknownKeys.entries.sortedBy<num>((entry) => -entry.value)) {
      buffer.writeln('  $value× $key');
    }

    if (timings.isNotEmpty) {
      final sorted = timings.sorted((a, b) => a.compareTo(b));
      String ms(int micros) => '${(micros / 1000).toStringAsFixed(1)} ms';
      buffer.writeln(
        '\nConversion time per page: median ${ms(sorted[sorted.length ~/ 2])}, '
        'p95 ${ms(sorted[(sorted.length * 0.95).floor().clamp(0, sorted.length - 1)])}, max ${ms(sorted.last)}',
      );
    }
    return buffer.toString();
  }

  static List<MapEntry<String, List<String>>> _byCount(Map<String, List<String>> map) =>
      map.entries.sortedBy<num>((entry) => -entry.value.length);
}

/// Audits [pages] with [codec] (built with the app's embeds).
AuditReport audit(StoryCodec codec, Iterable<AuditPage> pages) {
  final report = AuditReport();
  for (final page in pages) {
    report.pages++;
    report.ops += page.ops.length;
    try {
      _auditPage(codec, page, report);
    } catch (error) {
      report.failed++;
      report.unexpected[page.location] = 'threw ${error.runtimeType}';
    }
  }
  return report;
}

void _auditPage(StoryCodec codec, AuditPage page, AuditReport report) {
  final losses = codec.quillImportLosses(page.ops);
  for (final loss in losses) {
    final key =
        '${loss.kind.name}${loss.key == null ? '' : ' ${loss.key}'}${loss.value == null ? '' : '=${loss.value}'}';
    report.losses.putIfAbsent(key, () => []).add('${page.location} line ${loss.line}');
  }

  final stopwatch = Stopwatch()..start();
  final markdown = codec.quillToMarkdown(page.ops);
  final written = codec.markdownToQuill(markdown);
  stopwatch.stop();
  report.timings.add(stopwatch.elapsedMicroseconds);

  if (losses.isEmpty && !isEquivalentQuill(page.ops, codec).matches(written, {})) {
    report.unexpected[page.location] = _firstDifference(
      canonicalQuill(page.ops, codec),
      canonicalQuill(written, codec),
    );
  }

  for (final op in page.ops) {
    if (op is! Map || op['insert'] is! Map) continue;
    final insert = Map<String, Object?>.from(op['insert'] as Map);
    final attributes = op['attributes'] is Map
        ? Map<String, Object?>.from(op['attributes'] as Map)
        : const <String, Object?>{};
    _auditEmbed(codec, insert, attributes, page.location, report);
  }
}

void _auditEmbed(
  StoryCodec codec,
  Map<String, Object?> insert,
  Map<String, Object?> attributes,
  String location,
  AuditReport report,
) {
  final key = insert.keys.firstWhereOrNull((key) => codec.registry.byQuillKey(key) != null);
  if (key == null) {
    if (!StoryEmbedRegistry.reservedQuillKeys.any(insert.containsKey)) {
      for (final unknown in insert.keys) {
        report.unknownKeys.update(unknown, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return;
  }

  final embed = codec.registry.byQuillKey(key)!;
  final node = embed.nodeFromQuill(QuillEmbedOp(key: key, insert: insert, attributes: attributes));
  if (node == null) {
    report.unknownKeys.update('$key (rejected value)', (count) => count + 1, ifAbsent: () => 1);
    return;
  }
  final written = embed.toQuillOf(node);
  if (written == null) {
    report.embedRewrites.putIfAbsent('$key: no toQuill (written as sp-markdown)', () => []).add(location);
    return;
  }

  final changes = <String>[
    if (written.key != key) 'key $key → ${written.key}',
    if (!const DeepCollectionEquality().equals(written.insert[written.key], insert[key])) '$key value rewritten',
    for (final name in {...attributes.keys, ...written.attributes.keys})
      if (attributes[name] != written.attributes[name]) '$name: ${attributes[name]} → ${written.attributes[name]}',
  ];
  if (changes.isNotEmpty) report.embedRewrites.putIfAbsent(changes.join(', '), () => []).add(location);
}

/// Where two canonical Quill pages first differ, described without their text.
String _firstDifference(List<Map<String, Object?>> original, List<Map<String, Object?>> written) {
  for (var i = 0; i < original.length || i < written.length; i++) {
    final a = original.elementAtOrNull(i);
    final b = written.elementAtOrNull(i);
    if (const DeepCollectionEquality().equals(a, b)) continue;
    return 'line $i: ${_shape(a)} became ${_shape(b)}';
  }
  return 'no difference found';
}

String _shape(Map<String, Object?>? line) {
  if (line == null) return '(no line)';
  final content = [
    for (final part in line['content'] as List)
      if ((part as Map).containsKey('text'))
        'text(${(part['text'] as String).length} chars ${part['attributes']})'
      else
        'embed(${part['embed']})',
  ];
  return 'block ${line['block']} [${content.join(', ')}]';
}
