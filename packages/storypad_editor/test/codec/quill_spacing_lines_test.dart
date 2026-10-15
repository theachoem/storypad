import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../support/test_embeds.dart';

/// Pages from before Markdown spaced embeds out with empty lines; with `dropQuillSpacingLines`, converting drops them
/// (the editor's embeds get space of their own).
void main() {
  final dropping = StoryCodec(embeds: testEmbeds, dropQuillSpacingLines: true);
  final keeping = StoryCodec(embeds: testEmbeds);

  const sticker = '<sp-sticker name="cat"></sp-sticker>';
  Map<String, Object?> embed([String name = 'cat']) => {
    'insert': {'sticker': name},
  };
  // A line break: right after an embed, it ends the embed's own line; any further one is an empty line.
  const line = {'insert': '\n'};

  test('one plain empty line above and below an embed goes; the rest stays', () {
    final ops = [
      {'insert': 'Before\n'},
      line,
      embed(),
      line,
      line,
      line,
      {'insert': 'After\n'},
    ];
    expect(keeping.quillPageToMarkdown(ops), 'Before\n\n&nbsp;\n\n$sticker\n\n&nbsp;\n\n&nbsp;\n\nAfter');
    // Above: the one line goes. Below: one of the two goes (two meant more room).
    expect(dropping.quillPageToMarkdown(ops), 'Before\n\n$sticker\n\n&nbsp;\n\nAfter');
    expect(dropping.checkQuillPage(ops).isLossless, isTrue);
  });

  test('the old flow: a title, an embed, a spacing line, then text', () {
    final ops = [
      embed(),
      line,
      line,
      {'insert': 'My other paragraph\n'},
    ];
    final markdown = dropping.quillPageToMarkdown(ops, title: 'Title');
    expect(markdown, '### Title\n\n$sticker\n\nMy other paragraph');
    expect(dropping.checkQuillPage(ops, title: 'Title', markdown: markdown).isLossless, isTrue);
  });

  test('a line between two embeds spaces both, and goes once', () {
    final ops = [embed('a'), line, line, embed('b'), line];
    expect(
      dropping.quillPageToMarkdown(ops),
      '<sp-sticker name="a"></sp-sticker>\n\n<sp-sticker name="b"></sp-sticker>',
    );
  });

  test('only plain empty lines: an aligned or styled one, or text, stays', () {
    final ops = [
      embed(),
      line,
      {
        'insert': '\n',
        'attributes': {'align': 'center'},
      },
      embed('b'),
      line,
    ];
    final markdown = dropping.quillPageToMarkdown(ops);
    expect(markdown, contains('&nbsp;'), reason: 'the centered empty line stays');
    expect(dropping.checkQuillPage(ops, markdown: markdown).isLossless, isTrue);
  });

  test('the check still fails anything else that changed', () {
    final ops = [
      embed(),
      line,
      line,
      line,
      {'insert': 'text\n'},
    ];
    // Dropping more than the spacing line isn't a conversion it accepts.
    expect(dropping.checkQuillPage(ops, markdown: '$sticker\n\ntext').isLossless, isFalse);
    expect(dropping.checkQuillPage(ops, markdown: '$sticker\n\n&nbsp;\n\ntext').isLossless, isTrue);
    // Nor a conversion that kept the spacing line.
    expect(dropping.checkQuillPage(ops, markdown: '$sticker\n\n&nbsp;\n\n&nbsp;\n\ntext').isLossless, isFalse);
  });

  test('off by default: every line kept', () {
    final ops = [
      embed(),
      line,
      line,
      const {'insert': 'text\n'},
    ];
    expect(keeping.quillPageToMarkdown(ops), '$sticker\n\n&nbsp;\n\ntext');
    expect(dropping.quillPageToMarkdown(ops), '$sticker\n\ntext');
    expect(keeping.checkQuillPage(ops).isLossless, isTrue);
  });
}
