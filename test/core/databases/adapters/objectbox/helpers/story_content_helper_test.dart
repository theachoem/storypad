import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/adapters/objectbox/helpers/story_content_helper.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';

void main() {
  StoryContentDbModel contentWith(StoryPageDbModel page) =>
      StoryContentDbModel.create().copyWith(title: 'T', plainText: 'p & q', richPages: [page]);

  group('StoryContentHelper: stored content reads back exactly', () {
    for (final markdown in [
      '&nbsp;\n\na\n\n&nbsp;\n\nb\n\n&nbsp;', // Blank lines: top, middle, bottom.
      '&#32;&#32;', // Kept whitespace.
      'a \\< b &amp; c &lt;d&gt; "q" it\'s',
      'x&nbsp;y &copy; &#169; &unknown;',
      '<u>under</u> <span style="color:#ff0000">red</span>',
    ]) {
      test(markdown.replaceAll('\n', r'\n'), () {
        final stored = StoryContentHelper.contentToString(
          contentWith(StoryPageDbModel.markdown(id: 1, markdown: markdown)),
        );
        final page = StoryContentHelper.stringToContent(stored).richPages!.single;
        expect(page.markdown, markdown);
      });
    }

    test('legacy Quill pages too, entity-like text included', () {
      final body = [
        {'insert': 'Tom &amp; Jerry &nbsp; <b>\n'},
      ];
      final stored = StoryContentHelper.contentToString(
        contentWith(StoryPageDbModel.legacy(id: 1, title: 'A &amp; B', body: body)),
      );
      final page = StoryContentHelper.stringToContent(stored).richPages!.single;
      expect(page.quillBody, body);
      expect(page.title, 'A &amp; B');
    });

    test('content stored by earlier versions still reads as before', () {
      // Earlier versions escaped `<`, `>`, quotes and lone `&`, but left existing entities.
      const stored =
          '{&quot;id&quot;:1,&quot;title&quot;:null,&quot;plain_text&quot;:&quot;Tom &amp; Jerry&quot;,'
          '&quot;created_at&quot;:&quot;2025-01-01T00:00:00.000&quot;,&quot;pages&quot;:null,&quot;rich_pages&quot;:[]}';
      expect(StoryContentHelper.stringToContent(stored).plainText, 'Tom & Jerry');
    });
  });
}
