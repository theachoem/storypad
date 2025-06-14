// ignore_for_file: implementation_imports

import 'dart:collection';
import 'package:flutter_quill/src/document/nodes/block.dart' show Block;
import 'package:flutter_quill/src/document/nodes/line.dart' show Line;
import 'package:flutter_quill/src/document/nodes/leaf.dart' show QuillText, Embed;
import 'package:flutter_quill/src/document/nodes/node.dart' show Root, Node;

class QuillRootToPlainTextService {
  static String call(
    Root root, {
    bool markdown = true,
  }) {
    return extract(root.children, markdown);
  }

  static String extract(
    LinkedList<Node> children,
    bool markdown, {
    String prefix = '',
  }) {
    return children.map((node) {
      if (node is Block) {
        return extract(node.children, markdown, prefix: prefix);
      } else if (node is Line) {
        final attrs = node.style.attributes;
        final indent = '\t' * (attrs['indent']?.value ?? 0);
        final list = attrs['list']?.value;
        final isBlockquote = attrs.containsKey('blockquote');
        final isCodeBlock = attrs.containsKey('code-block');

        String linePrefix = indent;

        if (isCodeBlock) {
          final content = extract(node.children, markdown, prefix: '');
          return '```\n$content\n```\n';
        }

        if (isBlockquote) {
          linePrefix += '> ';
        } else if (list == 'bullet') {
          linePrefix += '- ';
        } else if (list == 'ordered') {
          linePrefix += '1. ';
        } else if (list == 'checked') {
          linePrefix += '- [x] ';
        } else if (list == 'unchecked') {
          linePrefix += '- [ ] ';
        }

        return "${extract(node.children, markdown, prefix: linePrefix)}\n";
      } else if (node is QuillText) {
        final text = node.value.trim();
        if (!markdown) return prefix + text;

        final style = node.style.attributes;

        final isBold = style.containsKey('bold');
        final isItalic = style.containsKey('italic');

        String result = text;
        if (isBold && isItalic) {
          result = '***$text***';
        } else if (isBold) {
          result = '**$text**';
        } else if (isItalic) {
          result = '*$text*';
        }

        return prefix + result;
      } else if (node is Embed) {
        final embed = node.value;

        // embed has no prefix.
        if (embed.type == 'image') {
          return '\n[image]';
        }

        return node.toPlainText();
      } else {
        return node.toPlainText();
      }
    }).join();
  }
}
