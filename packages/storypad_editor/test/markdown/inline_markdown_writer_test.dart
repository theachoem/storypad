import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/src/markdown/inline_markdown_writer.dart';
import 'package:super_editor/super_editor.dart';

AttributedText _text(String text, [List<(Attribution, int, int)> spans = const []]) {
  final attributedText = AttributedText(text);
  for (final (attribution, start, end) in spans) {
    attributedText.addAttribution(attribution, SpanRange(start, end));
  }
  return attributedText;
}

String _write(AttributedText text) => const InlineMarkdownWriter().write(text);

void main() {
  group('single attributions', () {
    test('bold', () => expect(_write(_text('Hello', [(boldAttribution, 0, 4)])), '**Hello**'));

    test('italics', () => expect(_write(_text('Hello', [(italicsAttribution, 0, 4)])), '*Hello*'));

    test('underline', () => expect(_write(_text('Hello', [(underlineAttribution, 0, 4)])), '<u>Hello</u>'));

    test('strikethrough uses GFM double-tilde', () {
      expect(_write(_text('Hello', [(strikethroughAttribution, 0, 4)])), '~~Hello~~');
    });

    test('code', () => expect(_write(_text('Hello', [(codeAttribution, 0, 4)])), '`Hello`'));

    test('color', () {
      expect(
        _write(_text('Hello', [(const ColorAttribution(Color(0xFF336699)), 0, 4)])),
        '<span style="color:#336699ff">Hello</span>',
      );
    });

    test('background color', () {
      expect(
        _write(_text('Hello', [(const BackgroundColorAttribution(Color(0x80FFCC00)), 0, 4)])),
        '<mark style="background-color:#ffcc0080">Hello</mark>',
      );
    });

    test('superscript and subscript', () {
      expect(_write(_text('Hi', [(const ScriptAttribution.superscript(), 0, 1)])), '<sup>Hi</sup>');
      expect(_write(_text('Hi', [(const ScriptAttribution.subscript(), 0, 1)])), '<sub>Hi</sub>');
    });

    test('link', () {
      expect(
        _write(_text('Hello', [(const LinkAttribution('https://example.com'), 0, 4)])),
        '[Hello](https://example.com)',
      );
    });
  });

  group('combinations', () {
    test('bold inside a link keeps both', () {
      expect(
        _write(_text('Hello', [(boldAttribution, 0, 4), (const LinkAttribution('https://example.com'), 0, 4)])),
        '[**Hello**](https://example.com)',
      );
    });

    test('color nested inside bold', () {
      expect(
        _write(_text('Hello World', [(boldAttribution, 0, 10), (const ColorAttribution(Color(0xFF336699)), 6, 10)])),
        '**Hello <span style="color:#336699ff">World</span>**',
      );
    });

    test('crossing bold and color are written as valid, non-crossing markup', () {
      final text = _text('Hello World foo', [
        (boldAttribution, 0, 10),
        (const ColorAttribution(Color(0xFF336699)), 6, 14),
      ]);

      expect(
        _write(text),
        '**Hello <span style="color:#336699ff">World</span>**<span style="color:#336699ff"> foo</span>',
      );
    });

    test('code is innermost, so other styles wrap it', () {
      expect(_write(_text('a b', [(boldAttribution, 0, 2), (codeAttribution, 0, 0)])), '**`a` b**');
    });
  });

  group('escaping', () {
    test('Markdown punctuation is backslash-escaped; <, >, & use character references', () {
      expect(_write(_text(r'\`*_~[]<>&')), r'\\&#96;\*\_\~\[\]&lt;&gt;&amp;');
    });

    test('other characters pass through', () {
      const input = 'Plain text 123 (parens) "quotes" - dash: colon; semi. period! #hash';
      expect(_write(_text(input)), input);
    });

    test('# is escaped only when asked (headings)', () {
      expect(const InlineMarkdownWriter().write(_text('C# #')), 'C# #');
      expect(const InlineMarkdownWriter().write(_text('C# #'), escapeHash: true), r'C\# \#');
    });

    test('code span content is verbatim, with a longer fence around backticks', () {
      expect(_write(_text('a*b<c>', [(codeAttribution, 0, 5)])), '`a*b<c>`');
      expect(_write(_text('a`b', [(codeAttribution, 0, 2)])), '``a`b``');
      expect(_write(_text('`a', [(codeAttribution, 0, 1)])), '`` `a ``');
      expect(_write(_text(' a ', [(codeAttribution, 0, 2)])), '`  a  `');
    });

    test('link destinations with spaces or parentheses use the <…> form', () {
      // Written the way Markdown normalizes it (spaces percent-encoded), so writing is a fixed point.
      expect(_write(_text('x', [(const LinkAttribution('a b'), 0, 0)])), '[x](a%20b)');
      expect(_write(_text('x', [(const LinkAttribution('a(b)'), 0, 0)])), '[x](<a(b)>)');
    });
  });

  group('line breaks', () {
    test('are written as <br> and carry no formatting', () {
      expect(_write(_text('a\nb', [(boldAttribution, 0, 2)])), '**a**<br>**b**');
    });

    test('leading, trailing and repeated breaks', () {
      expect(_write(_text('\na\n\n')), '<br>a<br><br>');
    });
  });

  group('falls back to HTML tags when delimiters would not parse back', () {
    test('emphasis starting with whitespace', () {
      expect(_write(_text(' a', [(boldAttribution, 0, 1)])), '<strong> a</strong>');
    });

    test('emphasis ending in punctuation followed by a letter', () {
      expect(_write(_text('(a)b', [(boldAttribution, 0, 2)])), '<strong>(a)</strong>b');
    });
  });

  test('unsupported attributions are dropped but their text is kept', () {
    expect(_write(_text('Hello', [(const NamedAttribution('spelling-error'), 0, 4)])), 'Hello');
  });
}
