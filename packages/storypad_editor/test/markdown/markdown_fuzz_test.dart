import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

/// Markdown the writer never produces -- hand-written, or from another app -- which the round-trip tests (built from
/// documents) never read. Whatever the reader makes of it must hold from then on:
///
/// 1. Reading never throws.
/// 2. What it read survives being written and read again (nothing it understood is lost on the first save).
/// 3. Writing that is a fixed point (a second save changes nothing).
///
/// And link and image destinations: Markdown may percent-encode one, but never change what it points to.
void main() {
  final codec = StoryCodec(embeds: testEmbedCodecs);

  group('hand-written Markdown', () {
    for (var seed = 0; seed < 2000; seed++) {
      test('seed $seed', () {
        final markdown = _randomMarkdown(Random(seed));
        final read = codec.decodeNodes(markdown);
        final written = codec.encode(read);
        final reread = codec.decodeNodes(written);

        expect(reread, DocumentEquivalence.matcher(read), reason: 'input:\n$markdown\n\nwritten:\n$written');
        expect(codec.encode(reread), written, reason: 'input:\n$markdown\n\nwritten:\n$written');
      });
    }
  });

  group('link and image destinations keep what they point to', () {
    // No embed claims <img>, so an image is a stock ImageNode written as `![](src)`.
    final plain = StoryCodec(embeds: [const StickerEmbedCodec()]);

    for (var seed = 0; seed < 2000; seed++) {
      test('seed $seed', () {
        final url = _randomUrl(Random(seed));

        final link = LinkAttribution(url);
        final paragraph = ParagraphNode(id: 'p', text: AttributedText('link')..addAttribution(link, SpanRange(0, 3)));
        final linkMarkdown = plain.encode([paragraph]);
        final linkRead = plain.decodeNodes(linkMarkdown).single as ParagraphNode;
        expect(linkRead.text.toPlainText(), 'link', reason: linkMarkdown);
        final readLink = linkRead.text.getAllAttributionsAt(0).whereType<LinkAttribution>().single;
        expect(_meaning(readLink.plainTextUri), _meaning(url), reason: linkMarkdown);
        expect(plain.canonicalize(linkMarkdown), linkMarkdown, reason: 'fixed point');

        final imageMarkdown = plain.encode([ImageNode(id: 'i', imageUrl: url)]);
        final imageRead = plain.decodeNodes(imageMarkdown).single;
        final src = imageRead is ImageNode ? imageRead.imageUrl : null;
        expect(src == null ? null : _meaning(src), _meaning(url), reason: imageMarkdown);
        expect(plain.canonicalize(imageMarkdown), imageMarkdown, reason: 'fixed point');
      });
    }
  });
}

/// [url] with its valid percent-escapes decoded (a lone `%` stays): two destinations mean the same when these are equal.
String _meaning(String url) {
  return url.replaceAllMapped(RegExp('(?:%[0-9A-Fa-f]{2})+'), (escapes) {
    try {
      return Uri.decodeComponent(escapes[0]!);
    } on FormatException {
      // Not UTF-8: decode the ASCII escapes in it alone.
      return escapes[0]!.replaceAllMapped(
        RegExp('%([0-7][0-9A-Fa-f])'),
        (escape) => String.fromCharCode(int.parse(escape[1]!, radix: 16)),
      );
    }
  });
}

const _urlAlphabet = 'abcXYZ019 &;#%()<>[]\\/?=:.,_-~!*\'"@\$+é©\t';

String _randomUrl(Random random) {
  const starts = ['https://x.com/', 'mailto:a@b.c?q=', '/path/', '', 'x.png?'];
  const pieces = ['&copy;', '&#169;', '&#xA9;', '&amp;', '&lt;', '&nbsp;', '&foo;', '&', '%20', '%', '%zz', '\\', '()'];
  final buffer = StringBuffer(starts[random.nextInt(starts.length)]);
  for (var i = random.nextInt(6); i >= 0; i--) {
    buffer.write(
      random.nextBool() ? pieces[random.nextInt(pieces.length)] : _urlAlphabet[random.nextInt(_urlAlphabet.length)],
    );
  }
  return buffer.toString();
}

const _words = ['a', 'Hello', 'wörld', '日本', '🙂', 'x_y', '1.', '#', '-', '+', '>', '=', '|', '!', ' ', '  ', '\t'];

const _inline = [
  '**',
  '*',
  '_',
  '__',
  '~~',
  '~',
  '`',
  '``',
  '[',
  ']',
  '(',
  ')',
  '](',
  '![',
  '\\',
  '\\*',
  '\\`',
  '<',
  '>',
  '&',
  '&amp;',
  '&copy;',
  '&#169;',
  '&#xA9;',
  '&nbsp;',
  '&#32;',
  '&lt;u&gt;',
  '<br>',
  '<br/>',
  '<wbr>',
  '<u>',
  '</u>',
  '<s>',
  '</s>',
  '<del>',
  '</del>',
  '<strong>',
  '</strong>',
  '<em>',
  '</em>',
  '<code>',
  '</code>',
  '<sup>',
  '</sup>',
  '<sub>',
  '</sub>',
  '<span style="color:#ff0000ff">',
  '<span style="color:#1234">',
  '</span>',
  '<mark style="background-color:#ffcc0080">',
  '</mark>',
  '<a href="https://x.com">',
  '</a>',
  '<p>',
  '</p>',
  '[l](https://x.com/?a=1&b=2)',
  '[l](<a b>)',
  '[l](x "title")',
  '<https://x.com>',
  '![a](x.png)',
  '**b**',
  '*i*',
  '`c`',
  '~~s~~',
  '<u>u</u>',
  '\r',
  ' ',
  ' ',
];

const _prefixes = [
  '',
  '',
  '',
  '# ',
  '### ',
  '###### ',
  '####### ',
  '#',
  '- ',
  '* ',
  '+ ',
  '1. ',
  '3) ',
  '- [ ] ',
  '- [x] ',
  '- [X] ',
  '> ',
  '> > ',
  '>',
  '    ',
  '  - ',
  '    - ',
  '        - [ ] ',
  '\t',
  '   ',
];

const _blocks = [
  '---',
  '***',
  '___',
  '```',
  '```dart\ncode\n```',
  '````\n```\n````',
  '~~~\nx\n~~~',
  '<div style="text-align:center">',
  '</div>',
  '<div data-indent="2">',
  '<img src="a.jpg">',
  '<img src="a.jpg" alt="x" data-align="center">',
  '<sp-sticker name="cat"></sp-sticker>',
  '<sp-gallery data-paths="a.jpg|b.jpg"></sp-gallery>',
  '<sp-unknown data-op="e30="></sp-unknown>',
  '<sp-unknown data-op="!!"></sp-unknown>',
  '<video src="v.mp4"></video>',
  '<table><tr><td>x</td></tr></table>',
  '&nbsp;',
  '<!-- comment -->',
  'Title\n=====',
  'Sub\n---',
];

String _randomInline(Random random) {
  final buffer = StringBuffer();
  for (var i = random.nextInt(8); i >= 0; i--) {
    buffer.write(random.nextBool() ? _words[random.nextInt(_words.length)] : _inline[random.nextInt(_inline.length)]);
  }
  return buffer.toString();
}

String _randomMarkdown(Random random) {
  final lines = <String>[];
  for (var i = random.nextInt(6); i >= 0; i--) {
    lines.add(
      random.nextInt(4) == 0
          ? _blocks[random.nextInt(_blocks.length)]
          : '${_prefixes[random.nextInt(_prefixes.length)]}${_randomInline(random)}',
    );
  }
  const separators = ['\n', '\n\n', '\n\n\n', '\r\n', '\r\n\r\n', '\n \n'];
  final buffer = StringBuffer(lines.first);
  for (final line in lines.skip(1)) {
    buffer
      ..write(separators[random.nextInt(separators.length)])
      ..write(line);
  }
  return buffer.toString();
}
