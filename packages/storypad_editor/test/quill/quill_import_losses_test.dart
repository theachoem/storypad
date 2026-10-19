import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../support/test_embeds.dart';

/// `quillImportLosses` reports exactly the formatting a conversion drops, and nothing a conversion keeps.
void main() {
  final codec = StoryCodec(embeds: testEmbedCodecs);

  List<Object?> line(String text, [Map<String, Object?>? block, Map<String, Object?>? inline]) => [
    {'insert': text, 'attributes': ?inline},
    {'insert': '\n', 'attributes': ?block},
  ];

  List<QuillImportLossKind> kinds(List<Object?> ops) => [for (final loss in codec.quillImportLosses(ops)) loss.kind];

  group('nothing is reported for what the conversion keeps', () {
    final kept = <String, List<Object?>>{
      'plain text': line('hello'),
      'every inline format': [
        for (final attributes in <Map<String, Object?>>[
          {'bold': true, 'italic': true, 'underline': true, 'strike': true},
          {'code': true},
          {'color': '#ff336699', 'background': '#FFCC00'},
          {'script': 'super'},
          {'link': 'https://example.com'},
          {'bold': false, 'color': null},
        ])
          {'insert': 'x', 'attributes': attributes},
        {'insert': '\n'},
      ],
      'headers with alignment and indent': line('t', {'header': 3, 'align': 'center', 'indent': 2}),
      'left alignment': line('t', {'align': 'left'}),
      'lists and tasks with indent': [
        ...line('a', {'list': 'bullet', 'indent': 1}),
        ...line('b', {'list': 'ordered'}),
        ...line('c', {'list': 'checked', 'indent': 6}),
      ],
      'a quote with alignment': line('q', {'blockquote': true, 'align': 'right', 'indent': 1}),
      'aligned list items and tasks': [
        ...line('a', {'list': 'bullet', 'align': 'center'}),
        ...line('b', {'list': 'checked', 'align': 'right', 'indent': 2}),
      ],
      'consecutive quote lines with different formats': [
        ...line('q1', {'blockquote': true}),
        ...line('q2', {'blockquote': true, 'align': 'center'}),
        ...line('q3', {'blockquote': true, 'indent': 1}),
      ],
      'consecutive quote lines sharing their format': [
        ...line('q1', {'blockquote': true, 'align': 'center'}),
        ...line('q2', {'blockquote': true, 'align': 'center'}),
      ],
      'a plain code block': [
        ...line('a', {'code-block': true}),
        ...line('b', {'code-block': true}),
      ],
      'inline formats on a line break (invisible)': line('t', {'bold': true, 'size': 'large', 'list': 'bullet'}),
      'embeds, known and unknown': [
        {
          'insert': {'gallery': 'a.jpg'},
          'attributes': {'x-align': 'center'},
        },
        {'insert': '\n'},
        {
          'insert': {'mystery': 1},
          'attributes': {'whatever': true},
        },
        {'insert': 'caption\n'},
      ],
      'CRLF and merged lines': [
        {'insert': 'a\r\nb\n\n'},
      ],
    };
    for (final MapEntry(:key, :value) in kept.entries) {
      test(key, () => expect(codec.quillImportLosses(value), isEmpty));
    }
  });

  test('invalid ops', () {
    expect(
      kinds([
        {'retain': 3},
        'text',
        {'insert': 'a', 'attributes': 'bold'},
        {'insert': 5},
        {'insert': '\n'},
      ]),
      [
        QuillImportLossKind.invalidOp,
        QuillImportLossKind.invalidOp,
        QuillImportLossKind.invalidOp,
        QuillImportLossKind.invalidOp,
      ],
    );
  });

  test('unsupported attributes, inline and block', () {
    final losses = codec.quillImportLosses([
      ...line('a', {'direction': 'rtl'}, {'font': 'serif', 'size': 'large'}),
    ]);
    expect(losses, [
      const QuillImportLoss(QuillImportLossKind.unsupportedAttribute, line: 0, key: 'direction', value: 'rtl'),
      const QuillImportLoss(QuillImportLossKind.unsupportedAttribute, line: 0, key: 'font', value: 'serif'),
      const QuillImportLoss(QuillImportLossKind.unsupportedAttribute, line: 0, key: 'size', value: 'large'),
    ]);
  });

  test('invalid values', () {
    expect(kinds(line('a', {'header': 7}, {'color': 'red'})), [
      QuillImportLossKind.invalidAttributeValue,
      QuillImportLossKind.invalidAttributeValue,
    ]);
    expect(kinds(line('a', {'list': 'dashed', 'align': 'middle', 'indent': -1}, {'bold': 'yes', 'script': 'x'})), [
      QuillImportLossKind.invalidAttributeValue,
      QuillImportLossKind.invalidAttributeValue,
      QuillImportLossKind.invalidAttributeValue,
      QuillImportLossKind.invalidAttributeValue,
      QuillImportLossKind.invalidAttributeValue,
    ]);
  });

  test('values read only partly', () {
    expect(codec.quillImportLosses(line('a', {'code-block': 'dart'})), [
      const QuillImportLoss(QuillImportLossKind.attributeValueDropped, line: 0, key: 'code-block', value: 'dart'),
    ]);
    expect(kinds(line('a', {'indent': 9})), [QuillImportLossKind.attributeValueDropped]);
  });

  test('block formats that can\'t be combined', () {
    expect(codec.quillImportLosses(line('a', {'list': 'bullet', 'header': 2})), [
      const QuillImportLoss(QuillImportLossKind.conflictingBlockFormat, line: 0, key: 'header', value: 2),
    ]);
    expect(kinds(line('a', {'code-block': true, 'blockquote': true, 'header': 1})), [
      QuillImportLossKind.conflictingBlockFormat,
      QuillImportLossKind.conflictingBlockFormat,
    ]);
    expect(kinds(line('a', {'header': 1, 'blockquote': true})), [QuillImportLossKind.conflictingBlockFormat]);
  });

  test('alignment and indent on code', () {
    expect(kinds(line('a', {'code-block': true, 'align': 'right', 'indent': 1})), [
      QuillImportLossKind.alignmentDropped,
      QuillImportLossKind.indentDropped,
    ]);
  });

  test('formatting inside code', () {
    expect(codec.quillImportLosses(line('a', {'code-block': true}, {'bold': true})), [
      const QuillImportLoss(QuillImportLossKind.formattingInCode, line: 0, key: 'bold', value: true),
    ]);
  });

  test('block formats on an embed\'s line', () {
    expect(
      kinds([
        {
          'insert': {'sticker': 'cat'},
        },
        {
          'insert': '\n',
          'attributes': {'align': 'center'},
        },
      ]),
      [QuillImportLossKind.embedLineFormat],
    );
  });

  test('lines are numbered by their line break', () {
    final losses = codec.quillImportLosses([
      {'insert': 'a\nb\n'},
      ...line('c', null, {'font': 'x'}),
    ]);
    expect(losses.single.line, 2);
  });
}
