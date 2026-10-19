import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/src/markdown/inline_markdown_reader.dart';
import 'package:super_editor/super_editor.dart';

AttributedText _read(String markdown) => const InlineMarkdownReader().read(markdown);

Set<Attribution> _at(AttributedText text, int offset) => text.getAllAttributionsAt(offset);

void main() {
  test('Markdown emphasis, strikethrough, code and links', () {
    final text = _read('**b** *i* ~~s~~ `c` [l](https://x.y)');

    expect(text.toPlainText(), 'b i s c l');
    expect(_at(text, 0), {boldAttribution});
    expect(_at(text, 2), {italicsAttribution});
    expect(_at(text, 4), {strikethroughAttribution});
    expect(_at(text, 6), {codeAttribution});
    expect(_at(text, 8), {const LinkAttribution('https://x.y')});
  });

  test('HTML tags for formats Markdown lacks', () {
    final text = _read(
      '<u>u</u><span style="color:#336699ff">c</span><mark style="background-color:#ffcc0080">m</mark>'
      '<sup>p</sup><sub>b</sub>',
    );

    expect(text.toPlainText(), 'ucmpb');
    expect(_at(text, 0), {underlineAttribution});
    expect(_at(text, 1), {const ColorAttribution(Color.fromARGB(0xff, 0x33, 0x66, 0x99))});
    expect(_at(text, 2), {const BackgroundColorAttribution(Color.fromARGB(0x80, 0xff, 0xcc, 0x00))});
    expect(_at(text, 3), {const ScriptAttribution.superscript()});
    expect(_at(text, 4), {const ScriptAttribution.subscript()});
  });

  test('HTML emphasis fallbacks', () {
    final text = _read('<strong>b</strong><em>i</em><del>s</del>');

    expect(_at(text, 0), {boldAttribution});
    expect(_at(text, 1), {italicsAttribution});
    expect(_at(text, 2), {strikethroughAttribution});
  });

  test('nested tags and Markdown inside tags', () {
    final text = _read('<mark style="background-color:#ffcc0080"><span style="color:#336699ff">**B** p</span></mark>');

    expect(text.toPlainText(), 'B p');
    expect(_at(text, 0), containsAll([boldAttribution]));
    expect(_at(text, 2).whereType<ColorAttribution>(), isNotEmpty);
    expect(_at(text, 2).whereType<BackgroundColorAttribution>(), isNotEmpty);
  });

  test('a tag nested in the same tag runs to its own closing tag', () {
    final underline = _read('<u>a<u>b</u>c</u>d');
    expect(underline.toPlainText(), 'abcd');
    for (final offset in [0, 1, 2]) {
      expect(_at(underline, offset), {underlineAttribution}, reason: 'offset $offset');
    }
    expect(_at(underline, 3), isEmpty);

    // No tag leaks into the text; the inner color is kept, as with any conflicting nested value.
    final color = _read('<span style="color:#ff0000ff">a <span style="color:#0000ffff">b</span> c</span>');
    expect(color.toPlainText(), 'a b c');
    expect(_at(color, 2), {const ColorAttribution(Color(0xFF0000FF))});
  });

  test('an opening tag without its closing tag is plain text', () {
    final text = _read('<u>a<u>b</u>');
    expect(text.toPlainText(), '<u>ab');
    expect(_at(text, 3), isEmpty);
    expect(_at(text, 4), {underlineAttribution});
  });

  test('<br> and backslash line breaks become \\n', () {
    expect(_read('a<br>b<br/>c').toPlainText(), 'a\nb\nc');
    expect(_read('a\\\nb').toPlainText(), 'a\nb');
  });

  test('escapes and character references', () {
    expect(_read(r'\*a\* &lt;b&gt; &amp; \# &#32;').toPlainText(), '*a* <b> & #  ');
  });

  test("super_editor's non-standard syntaxes are plain text", () {
    expect(_read('a ¬u¬ b').toPlainText(), 'a ¬u¬ b');
    expect(_read('a ¬u¬ b').getAllAttributionsAt(2), isEmpty);
  });

  test('empty tags do not throw', () {
    expect(_read('a<u></u>b<strong></strong>').toPlainText(), 'ab');
  });

  test('invalid color values are ignored', () {
    final text = _read('<span style="color:#1234567">x</span>');

    expect(text.toPlainText(), 'x');
    expect(_at(text, 0), isEmpty);
  });
}
