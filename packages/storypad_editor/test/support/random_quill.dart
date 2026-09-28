import 'dart:math';

import 'package:super_editor/super_editor.dart';

import 'random_documents.dart';

/// Seeded random Quill ops, and what a document looks like after a trip through Quill.

const _inline = <Map<String, Object?>>[
  {'bold': true},
  {'italic': true},
  {'underline': true, 'strike': true},
  {'code': true},
  {'color': '#FF336699'},
  {'background': '#80FFCC00', 'italic': true},
  {'link': 'https://example.com/x y'},
  {'script': 'sub'},
  {'bold': false, 'color': null},
];

const _lossyInline = <Map<String, Object?>>[
  {'size': 'large', 'font': 'serif'},
  {'color': 'not a color'},
];

const _block = <Map<String, Object?>>[
  {'header': 1},
  {'header': 3, 'align': 'center'},
  {'blockquote': true},
  {'code-block': true},
  {'list': 'bullet'},
  {'list': 'ordered', 'indent': 2},
  {'list': 'checked', 'indent': 1},
  {'list': 'unchecked'},
  {'align': 'justify', 'indent': 3},
  {'align': 'left', 'indent': 0},
];

const _lossyBlock = <Map<String, Object?>>[
  {'blockquote': true, 'indent': 1},
  {'list': 'unchecked', 'align': 'right'},
  {'direction': 'rtl'},
  {'code-block': 'dart'},
];

/// Random Quill ops: text runs with inline formats, block formats, embeds (registered in `testEmbedCodecs`, legacy
/// keys, rejected values, unknown keys) and, unless [lossless], formatting the conversion drops.
List<Object?> randomQuillOps(Random random, {bool lossless = false}) {
  final inline = lossless ? _inline : [..._inline, ..._lossyInline];
  final block = lossless ? _block : [..._block, ..._lossyBlock];

  final ops = <Object?>[];
  for (var line = 1 + random.nextInt(10); line > 0; line--) {
    var lineBlock = random.nextInt(3) == 0 ? block[random.nextInt(block.length)] : null;
    switch (random.nextInt(6)) {
      case 0:
        ops.add({
          'insert': switch (random.nextInt(5)) {
            0 => {'sticker': randomString(random, lineBreaks: false)},
            1 => {'gallery': 'a.jpg|b c.jpg'},
            2 => {'photo': 'x.jpg'},
            3 => {'divider': 'hr'},
            _ => {'mystery-${random.nextInt(3)}': randomString(random)},
          },
          if (random.nextBool()) 'attributes': {'x-align': 'center', 'custom-embed-size': 'max'},
        });
        // Block formats on an embed's own line are dropped.
        if (lossless) lineBlock = null;
      default:
        for (var run = random.nextInt(4); run > 0; run--) {
          ops.add({
            'insert': randomString(random, lineBreaks: false),
            // Code blocks hold plain text: formatting inside one is dropped.
            if (random.nextBool() && !(lossless && lineBlock?['code-block'] != null))
              'attributes': inline[random.nextInt(inline.length)],
          });
        }
    }
    ops.add({'insert': '\n', 'attributes': ?lineBlock});
  }
  return ops;
}

/// [nodes] as they read back after a trip through Quill, which has no line breaks inside a line and no boundary
/// between consecutive quote lines or code lines:
///
/// - text nodes are split at their line breaks (`\r` counts as one), each part keeping the node's format;
/// - then consecutive quotes merge into the first (keeping its alignment and indent), joined by `\n`, and so do
///   consecutive code blocks.
List<DocumentNode> quillNormalized(List<DocumentNode> nodes) {
  final split = <DocumentNode>[];
  for (final node in nodes) {
    if (node is! TextNode) {
      split.add(node);
      continue;
    }
    // Breaks as Quill reads them: "\r\n", a lone "\r", or "\n".
    final text = node.text.toPlainText();
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '\n' && i > 0 && text[i - 1] == '\r') {
        start = i + 1;
      } else if (text[i] == '\n' || text[i] == '\r') {
        split.add(_withText(node, node.text.copyText(start, i)));
        start = i + 1;
      }
    }
    split.add(start == 0 ? node : _withText(node, node.text.copyText(start)));
  }

  final merged = <DocumentNode>[];
  for (final node in split) {
    final previous = merged.lastOrNull;
    final kind = _mergeKind(node);
    if (kind != null && previous is ParagraphNode && _mergeKind(previous) == kind) {
      final text = previous.text.copyAndAppend(AttributedText('\n')).copyAndAppend((node as ParagraphNode).text);
      merged[merged.length - 1] = previous.copyParagraphWith(text: text);
    } else {
      merged.add(node);
    }
  }
  return merged;
}

Attribution? _mergeKind(DocumentNode node) {
  if (node is! ParagraphNode) return null;
  final Attribution? blockType = node.getMetadataValue(NodeMetadata.blockType);
  return blockType == blockquoteAttribution || blockType == codeAttribution ? blockType : null;
}

DocumentNode _withText(TextNode node, AttributedText text) {
  return switch (node) {
    ParagraphNode() => node.copyParagraphWith(id: Editor.createNodeId(), text: text),
    ListItemNode() => node.copyListItemWith(id: Editor.createNodeId(), text: text),
    TaskNode() => node.copyTaskWith(id: Editor.createNodeId(), text: text),
    _ => throw UnsupportedError('$node'),
  };
}
