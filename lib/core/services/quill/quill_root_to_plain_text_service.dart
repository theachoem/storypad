// ignore_for_file: implementation_imports

import 'dart:collection';
import 'package:flutter_quill/flutter_quill.dart';

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
      if (node.toPlainText().contains('storypad')) {
        // print(node.runtimeType);
      }

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
          final content = extract(node.children, markdown, prefix: linePrefix);
          return '```\n$content\n```\n';
        }

        if (isBlockquote) {
          final content = extract(node.children, markdown, prefix: '');

          final indentCount = attrs['indent']?.value ?? 0;
          final quotePrefix = '>' * indentCount + '\t';

          return '$quotePrefix$content\n';
        }

        if (list == 'bullet') {
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
        final text = node.value;
        final style = node.style.attributes;

        if (!markdown) return prefix + text;

        final isBold = style.containsKey('bold');
        final isItalic = style.containsKey('italic');
        final isLink = style.containsKey(Attribute.link.key);

        String result = text;

        if (isLink) {
          return '$prefix[${node.toPlainText()}](${style[Attribute.link.key]?.value})';
        } else if (isBold && isItalic) {
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
