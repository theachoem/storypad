import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../support/test_embeds.dart';

void main() {
  group('render', () {
    test('writes attributes in insertion order', () {
      final element = StoryHtmlElement('img', attributes: {'src': 'a.jpg', 'data-size': 'max'});

      expect(element.render(), '<img src="a.jpg" data-size="max">');
    });

    test('void elements have no closing tag; others always close', () {
      expect(StoryHtmlElement('img').render(), '<img>');
      expect(StoryHtmlElement('audio').render(), '<audio></audio>');
    });

    test('renders text and children', () {
      final element = StoryHtmlElement(
        'sp-album',
        children: [
          StoryHtmlElement('img', attributes: {'src': 'a.jpg'}),
          StoryHtmlElement('time', text: '2024'),
        ],
      );

      expect(element.render(), '<sp-album><img src="a.jpg"><time>2024</time></sp-album>');
    });

    test('escapes attribute values and text, and stays on one line', () {
      final element = StoryHtmlElement('sp-note', attributes: {'title': 'a "b" & <c>\nd'}, text: 'x < y & z\nw');

      final html = element.render();
      expect(html, '<sp-note title="a &quot;b&quot; &amp; &lt;c&gt;&#10;d">x &lt; y &amp; z&#10;w</sp-note>');
      expect(html, isNot(contains('\n')));
    });

    test('raw elements render verbatim', () {
      expect(StoryHtmlElement.raw('<sp-future x="1">').render(), '<sp-future x="1">');
    });
  });

  group('parse', () {
    test('round-trips through render', () {
      final element = StoryHtmlElement(
        'sp-album',
        attributes: {'data-align': 'center', 'title': 'a "quoted" & <tagged>'},
        children: [
          StoryHtmlElement('img', attributes: {'src': 'a b.jpg'}),
          StoryHtmlElement('video', attributes: {'src': 'c.mp4'}),
        ],
      );

      expect(StoryHtmlElement.tryParse(element.render()), element);
    });

    test('reads text content and decodes character references', () {
      final element = StoryHtmlElement.tryParse('<time datetime="2024">line&#10;two</time>')!;

      expect(element.tag, 'time');
      expect(element['datetime'], '2024');
      expect(element.text, 'line\ntwo');
    });

    test('lowercases tag names', () {
      expect(StoryHtmlElement.tryParse('<IMG SRC="a.jpg">')!.tag, 'img');
    });

    test('returns null when there is no element', () {
      expect(StoryHtmlElement.tryParse('just text'), isNull);
    });
  });

  group('validation', () {
    test('rejects invalid tag and attribute names', () {
      expect(() => StoryHtmlElement('Img'), throwsArgumentError);
      expect(() => StoryHtmlElement('img', attributes: {'bad name': 'x'}), throwsArgumentError);
    });

    test('rejects text and children together', () {
      expect(() => StoryHtmlElement('p', text: 'x', children: [StoryHtmlElement('img')]), throwsArgumentError);
    });

    test('rejects multi-line raw html', () {
      expect(() => StoryHtmlElement.raw('<a>\n</a>'), throwsArgumentError);
    });
  });

  test('reads typed attributes', () {
    final element = StoryHtmlElement('img', attributes: {'data-align': 'right'});

    expect(element.attribute(galleryAlignment), GalleryAlignment.right);
    expect(element.attribute(gallerySize), GallerySize.normal);
  });
}
