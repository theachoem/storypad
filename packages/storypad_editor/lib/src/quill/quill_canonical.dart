import 'package:collection/collection.dart';

import '../codec/node_description.dart';
import '../codec/story_codec.dart';
import '../embed/quill_embed_op.dart';
import '../embed/story_embed_node.dart';
import '../embed/unknown_embed_value.dart';
import '../markdown/markdown_link_destination.dart';
import 'quill_exporter.dart';
import 'quill_importer.dart';

/// Quill ops reduced ([of]) to what they mean to a StoryPad story, for comparing two Deltas that were written
/// differently: one entry per line, `{'block': {...}, 'content': [...]}`, where content is text runs
/// (`{'text', 'attributes'}`) and embeds (`{'embed': type, 'value': value}`, compared by the embed's value).
///
/// Differences that carry no meaning are normalized away, matching how `StoryCodec.decodeQuill` reads Quill:
///
/// - op boundaries (text runs with equal attributes merge), CRLF, and non-insert ops;
/// - `false`/`null` attributes, left alignment, zero indent, colors in either `#rrggbb` or `#aarrggbb`, and link
///   spellings Markdown normalizes (e.g. percent-encoded spaces); inline formats on a line's `\n` (invisible);
/// - an embed sharing a line with text: the embed is its own line (the text before it an unformatted line, the text
///   after it keeps the line's formatting), and an embed's own empty line, unless it's a list item or task;
/// - an embed's op as long as its embed reads it as the same value (e.g. a default attribute written or omitted, or a
///   legacy key), and the package's own `divider`/`sp-markdown` ops by what they hold.
class QuillCanonical {
  const QuillCanonical(this.codec);

  /// Reads embed ops, so two spellings of one embed compare equal.
  final StoryCodec codec;

  List<Map<String, Object?>> of(List<Object?> ops) {
    final lines = <Map<String, Object?>>[];
    var segments = <Map<String, Object?>>[];
    for (final op in QuillImporter.sanitize(ops)) {
      if (op['insert'] == '\n') {
        lines.addAll(_lines(segments, _block(op['attributes'])));
        segments = [];
      } else {
        segments.add(op);
      }
    }
    if (segments.isNotEmpty) lines.addAll(_lines(segments, const {}));
    return lines;
  }

  static const _inlineKeys = {
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

  static final _hexColor = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

  List<Map<String, Object?>> _lines(List<Map<String, Object?>> segments, Map<String, Object?> block) {
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
          'content': [_embed(Map<String, Object?>.from(insert), segment['attributes'])],
        });
        content = [];
        sawEmbed = true;
      }
    }

    // The rest of the line keeps its formatting. Right after an embed, an empty rest isn't content -- unless it's a
    // list item or task, which the importer keeps.
    if (!sawEmbed || content.isNotEmpty || block.containsKey('list')) {
      lines.add({'block': block, 'content': content});
    }
    return lines;
  }

  static Map<String, Object?> _block(Object? attributes) {
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

  static Map<String, Object?> _inline(Object? attributes) {
    if (attributes is! Map) return const {};
    final inline = <String, Object?>{};
    for (final MapEntry(:key, :value) in attributes.entries) {
      if (value == null || value == false) continue;
      if ((key == 'color' || key == 'background') && value is String && _hexColor.hasMatch(value.trim())) {
        final hex = value.trim().substring(1);
        inline['$key'] = int.parse(hex, radix: 16) + (hex.length == 6 ? 0xFF000000 : 0);
      } else if (key == 'link' && value is String) {
        inline['link'] = MarkdownLinkDestination.canonical(value);
      } else {
        inline['$key'] = value;
      }
    }
    return inline;
  }

  Map<String, Object?> _embed(Map<String, Object?> insert, Object? attributes) {
    if (insert.containsKey(QuillExporter.dividerKey)) return {'embed': 'divider'};

    final ops = [
      {'insert': insert, 'attributes': ?attributes},
      {'insert': '\n'},
    ];
    final nodes = codec.decodeQuill(ops);
    final node = nodes.length == 1 ? nodes.single : null;
    if (node is StoryEmbedNode && node.value is! UnknownQuillEmbed) return {'embed': node.type, 'value': node.value};
    if (node != null && node is! StoryEmbedNode) return {'embed': NodeDescription(node).describe()};

    final key = insert.keys.firstOrNull ?? '';
    return {'embed': 'unknown', 'value': QuillEmbedOp(key: key, insert: insert, attributes: _map(attributes)).toJson()};
  }

  static Map<String, Object?> _map(Object? value) => value is Map ? Map<String, Object?>.from(value) : const {};
}
