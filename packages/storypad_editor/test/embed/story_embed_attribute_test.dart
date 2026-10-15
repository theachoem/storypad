import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../support/test_embeds.dart';

QuillEmbedOp _op(Map<String, Object?> attributes) =>
    QuillEmbedOp(key: 'gallery', insert: const {'gallery': 'a.jpg'}, attributes: attributes);

void main() {
  group('enumeration', () {
    test('reads the Quill attribute', () {
      expect(_op({'x-align': 'center'}).attribute(galleryAlignment), GalleryAlignment.center);
      expect(_op({'x-size': 'max'}).attribute(gallerySize), GallerySize.max);
    });

    test('reads the HTML attribute', () {
      final element = StoryHtmlElement('img', attributes: {'data-align': 'left', 'data-size': 'max'});

      expect(element.attribute(galleryAlignment), GalleryAlignment.left);
      expect(element.attribute(gallerySize), GallerySize.max);
    });

    test('an explicitly written fallback value reads as the fallback', () {
      expect(_op({'x-size': 'default'}).attribute(gallerySize), GallerySize.normal);
    });

    test('missing, null, or unrecognized values read as the fallback', () {
      expect(_op({}).attribute(galleryAlignment), GalleryAlignment.none);
      expect(_op({'x-align': null}).attribute(galleryAlignment), GalleryAlignment.none);
      expect(_op({'x-align': 'diagonal'}).attribute(galleryAlignment), GalleryAlignment.none);
      expect(_op({'x-align': 42}).attribute(galleryAlignment), GalleryAlignment.none);
    });

    test('trims surrounding whitespace', () {
      expect(_op({'x-align': ' right '}).attribute(galleryAlignment), GalleryAlignment.right);
    });

    test('toHtml omits the fallback', () {
      expect(galleryAlignment.toHtml(GalleryAlignment.none), isEmpty);
      expect(galleryAlignment.toHtml(GalleryAlignment.center), {'data-align': 'center'});
    });

    test('toQuill omits the fallback, and round-trips through Quill', () {
      expect(galleryAlignment.toQuill(GalleryAlignment.none), isEmpty);
      expect(galleryAlignment.toQuill(GalleryAlignment.center), {'x-align': 'center'});
      expect(_op(galleryAlignment.toQuill(GalleryAlignment.right)).attribute(galleryAlignment), GalleryAlignment.right);
    });

    test('format throws for a value without a string form', () {
      expect(() => galleryAlignment.format(GalleryAlignment.none), throwsArgumentError);
    });
  });

  group('custom conversion', () {
    const width = StoryEmbedAttribute<int>(
      quillKey: 'width',
      htmlName: 'width',
      parse: int.tryParse,
      format: _formatInt,
      fallback: 0,
    );

    test('parses non-string Quill values from their string form', () {
      expect(_op({'width': 320}).attribute(width), 320);
      expect(_op({'width': '640'}).attribute(width), 640);
      expect(_op({'width': 'wide'}).attribute(width), 0);
    });

    test('round-trips through HTML', () {
      final element = StoryHtmlElement('img', attributes: width.toHtml(320));

      expect(element.attribute(width), 320);
    });
  });

  test('an attribute without a Quill key always reads the fallback from Quill', () {
    const htmlOnly = StoryEmbedAttribute<GallerySize>.enumeration(
      htmlName: 'data-size',
      values: {GallerySize.max: 'max'},
      fallback: GallerySize.normal,
    );

    expect(_op({'data-size': 'max'}).attribute(htmlOnly), GallerySize.normal);
    expect(htmlOnly.toQuill(GallerySize.max), isEmpty);
  });
}

String _formatInt(int value) => '$value';
