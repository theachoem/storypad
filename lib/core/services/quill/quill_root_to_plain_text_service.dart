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
    Map<int, int>? orderedListCounter,
  }) {
    orderedListCounter ??= {};

    return children.map((node) {
      if (node is Block) {
        return extract(node.children, markdown, prefix: prefix, orderedListCounter: orderedListCounter);
      } else if (node is Line) {
        final attrs = node.style.attributes;
        final indentLevel = int.tryParse("${attrs['indent']?.value}");
        final indent = '\t' * (indentLevel ?? 0);
        final list = attrs['list']?.value;
        final isBlockquote = attrs.containsKey('blockquote');
        final isCodeBlock = attrs.containsKey('code-block');

        String linePrefix = indent;

        if (isCodeBlock) {
          final content = extract(node.children, markdown, prefix: linePrefix, orderedListCounter: orderedListCounter);
          return '```\n$content\n```\n';
        }

        // output: >> for multiple indent.
        if (isBlockquote) {
          final content = extract(node.children, markdown, prefix: '', orderedListCounter: orderedListCounter);
          final quotePrefix = indentLevel != null ? '> ' * (indentLevel + 1) : '> ';

          return '$quotePrefix$content\n';
        }

        if (list == 'bullet') {
          linePrefix += '- ';
        } else if (list == 'ordered') {
          int index = orderedListCounter![indentLevel ?? 0] = (orderedListCounter[indentLevel ?? 0] ?? 0) + 1;
          final formattedIndex = switch (indentLevel) {
            0 => '$index.',
            1 => '${String.fromCharCode(96 + index)}.',
            2 => '${_toRoman(index).toLowerCase()}.',
            _ => '$index.',
          };

          linePrefix += '$formattedIndex ';
        } else if (list == 'checked') {
          linePrefix += markdown ? '- [x] ' : '✅ ';
        } else if (list == 'unchecked') {
          linePrefix += markdown ? '- [ ] ' : '⏹️ ';
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
          return '';
        }

        return node.toPlainText();
      } else {
        return node.toPlainText();
      }
    }).join();
  }

  static String _toRoman(int number) {
    final numerals = {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };

    var result = '';
    var n = number;

    numerals.forEach((value, symbol) {
      while (n >= value) {
        result += symbol;
        n -= value;
      }
    });

    return result;
  }
}
