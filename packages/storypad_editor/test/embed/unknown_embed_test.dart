import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';

const _unknown = UnknownEmbedCodec();

void main() {
  test('imports any Quill op whole, attributes included', () {
    const op = QuillEmbedOp(key: 'mystery', insert: {'mystery': 'value'}, attributes: {'custom-embed-size': 'max'});

    final value = _unknown.fromQuill(op) as UnknownQuillEmbed;
    expect(value.op, {
      'insert': {'mystery': 'value'},
      'attributes': {'custom-embed-size': 'max'},
    });
    expect(value.key, 'mystery');
  });

  test('a Quill op round-trips through its sp-unknown element', () {
    final value = UnknownQuillEmbed({
      'insert': {
        'mystery': {'nested': '"quoted" <tag> & ünïcode\n'},
      },
      'attributes': {'x': 1},
    });

    final html = _unknown.toHtml(value).render();
    expect(html, startsWith('<sp-unknown data-op="'));
    expect(_unknown.fromHtml(StoryHtmlElement.tryParse(html)!), value);
  });

  test('a malformed data-op reads as null (the codec then keeps the line verbatim)', () {
    expect(_unknown.fromHtml(StoryHtmlElement('sp-unknown', attributes: {'data-op': 'not base64!'})), isNull);
    expect(_unknown.fromHtml(StoryHtmlElement('sp-unknown', attributes: {'data-op': 'WzFd'})), isNull); // "[1]"
    expect(_unknown.fromHtml(StoryHtmlElement('sp-unknown')), isNull);
  });

  test('an unknown HTML line renders verbatim', () {
    const value = UnknownHtmlEmbed('<sp-future data-x="1"></sp-future>');

    expect(_unknown.toHtml(value).render(), '<sp-future data-x="1"></sp-future>');
    expect(value.tag, 'sp-future');
  });

  test('values have deep equality', () {
    expect(
      UnknownQuillEmbed({
        'insert': {
          'a': [1, 2],
        },
      }),
      UnknownQuillEmbed({
        'insert': {
          'a': [1, 2],
        },
      }),
    );
    expect(const UnknownHtmlEmbed('<x>'), const UnknownHtmlEmbed('<x>'));
  });
}
