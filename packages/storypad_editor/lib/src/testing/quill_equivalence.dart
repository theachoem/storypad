import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../codec/story_codec.dart';
import '../embed/quill_embed_op.dart';
import '../embed/story_embed_node.dart';
import '../embed/unknown_embed.dart';
import '../markdown/inline_markdown_writer.dart';
import '../quill/quill_exporter.dart';
import '../quill/quill_importer.dart';
import 'document_equivalence.dart';

/// Quill ops reduced to what they mean to a StoryPad story, for comparing two Deltas that were written differently:
/// one entry per line, `{'block': {...}, 'content': [...]}`, where content is text runs (`{'text', 'attributes'}`)
/// and embeds (`{'embed': type, 'value': value}`, compared by the embed's value).
///
/// Differences that carry no meaning are normalized away, matching how `StoryCodec.decodeQuill` reads Quill:
///
/// - op boundaries (text runs with equal attributes merge), CRLF, and non-insert ops;
/// - `false`/`null` attributes, left alignment, zero indent, colors in either `#rrggbb` or `#aarrggbb`, and link
///   spellings Markdown normalizes (e.g. percent-encoded spaces); inline formats on a line's `\n` (invisible);
/// - an embed sharing a line with text: the embed is its own line (the text before it an unformatted line, the text
///   after it keeps the line's formatting), and an embed's own empty line, unless it's a list item or task;
/// - trailing empty lines;
/// - an embed's op as long as its embed reads it as the same value (e.g. a default attribute written or omitted, or a
///   legacy key), and the package's own `divider`/`sp-markdown` ops by what they hold.
List<Map<String, Object?>> canonicalQuill(List<Object?> ops, StoryCodec codec) {
  final lines = <Map<String, Object?>>[];
  var segments = <Map<String, Object?>>[];
  for (final op in QuillImporter.sanitize(ops)) {
    if (op['insert'] == '\n') {
      lines.addAll(_lines(segments, _block(op['attributes']), codec));
      segments = [];
    } else {
      segments.add(op);
    }
  }
  if (segments.isNotEmpty) lines.addAll(_lines(segments, const {}, codec));

  while (lines.isNotEmpty && (lines.last['content'] as List).isEmpty && (lines.last['block'] as Map).isEmpty) {
    lines.removeLast();
  }
  return lines;
}

/// Matches Quill ops (a `List`) equivalent to [expected] as [canonicalQuill] sees them.
Matcher isEquivalentQuill(List<Object?> expected, StoryCodec codec) => _EquivalentQuill(expected, codec);

const _inlineKeys = {
  'bold',
  'italic',
  'underline',
  'strike',
  'code',
  'color',
  'background',
  'script',
  'link',
  'font',
  'size',
  'small',
};

final _hexColor = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

List<Map<String, Object?>> _lines(List<Map<String, Object?>> segments, Map<String, Object?> block, StoryCodec codec) {
  final lines = <Map<String, Object?>>[];
  var content = <Map<String, Object?>>[];
  var sawEmbed = false;

  for (final segment in segments) {
    final insert = segment['insert'];
    if (insert is String) {
      final attributes = _inline(segment['attributes']);
      final last = content.lastOrNull;
      if (last != null &&
          last.containsKey('text') &&
          const DeepCollectionEquality().equals(last['attributes'], attributes)) {
        content[content.length - 1] = {'text': '${last['text']}$insert', 'attributes': attributes};
      } else {
        content.add({'text': insert, 'attributes': attributes});
      }
    } else if (insert is Map) {
      // Text before an embed is its own, unformatted line; the embed is its own line.
      if (content.isNotEmpty) lines.add({'block': const <String, Object?>{}, 'content': content});
      lines.add({
        'block': const <String, Object?>{},
        'content': [_embed(Map<String, Object?>.from(insert), segment['attributes'], codec)],
      });
      content = [];
      sawEmbed = true;
    }
  }

  // The rest of the line keeps its formatting. Right after an embed, an empty rest isn't content -- unless it's a list
  // item or task, which the importer keeps.
  if (!sawEmbed || content.isNotEmpty || block.containsKey('list')) {
    lines.add({'block': block, 'content': content});
  }
  return lines;
}

Map<String, Object?> _block(Object? attributes) {
  if (attributes is! Map) return const {};
  final block = <String, Object?>{};
  for (final MapEntry(:key, :value) in attributes.entries) {
    if (value == null || value == false || _inlineKeys.contains(key)) continue;
    if (key == 'align' && value == 'left') continue;
    if (key == 'indent') {
      final indent = value is num ? value.toInt() : int.tryParse('$value');
      if (indent == 0) continue;
      block['indent'] = indent ?? value;
      continue;
    }
    block['$key'] = value;
  }
  return block;
}

Map<String, Object?> _inline(Object? attributes) {
  if (attributes is! Map) return const {};
  final inline = <String, Object?>{};
  for (final MapEntry(:key, :value) in attributes.entries) {
    if (value == null || value == false) continue;
    if ((key == 'color' || key == 'background') && value is String && _hexColor.hasMatch(value.trim())) {
      final hex = value.trim().substring(1);
      inline['$key'] = int.parse(hex, radix: 16) + (hex.length == 6 ? 0xFF000000 : 0);
    } else if (key == 'link' && value is String) {
      inline['link'] = canonicalLinkDestination(value);
    } else {
      inline['$key'] = value;
    }
  }
  return inline;
}

Map<String, Object?> _embed(Map<String, Object?> insert, Object? attributes, StoryCodec codec) {
  if (insert.containsKey(QuillExporter.dividerKey)) return {'embed': 'divider'};

  final ops = [
    {'insert': insert, 'attributes': ?attributes},
    {'insert': '\n'},
  ];
  final nodes = codec.decodeQuill(ops);
  final node = nodes.length == 1 ? nodes.single : null;
  if (node is StoryEmbedNode && node.value is! UnknownQuillEmbed) return {'embed': node.type, 'value': node.value};
  if (node != null && node is! StoryEmbedNode) return {'embed': describeNode(node)};

  final key = insert.keys.firstOrNull ?? '';
  return {'embed': 'unknown', 'value': QuillEmbedOp(key: key, insert: insert, attributes: _map(attributes)).toJson()};
}

Map<String, Object?> _map(Object? value) => value is Map ? Map<String, Object?>.from(value) : const {};

String _describe(List<Map<String, Object?>> lines) {
  return lines.map((line) => jsonEncode(line, toEncodable: (value) => value.toString())).join('\n  ');
}

class _EquivalentQuill extends Matcher {
  _EquivalentQuill(List<Object?> expected, this.codec) : expected = canonicalQuill(expected, codec);

  final List<Map<String, Object?>> expected;
  final StoryCodec codec;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! List) return false;
    return const DeepCollectionEquality().equals(canonicalQuill(item, codec), expected);
  }

  @override
  Description describe(Description description) => description.add('Quill equivalent to:\n  ${_describe(expected)}');

  @override
  Description describeMismatch(Object? item, Description mismatch, Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is! List) return mismatch.add('is not a list of ops');
    return mismatch.add('reads as:\n  ${_describe(canonicalQuill(item, codec))}');
  }
}
