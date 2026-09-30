import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

final _codec = StoryCodec();

String _write(List<DocumentNode> nodes) => _codec.encode(nodes);

ParagraphNode _paragraph(String text, {Attribution? blockType, String? align, int indent = 0}) {
  return ParagraphNode(
    id: Editor.createNodeId(),
    text: AttributedText(text),
    indent: indent,
    metadata: {NodeMetadata.blockType: ?blockType, TextNodeMetadata.textAlign: ?align},
  );
}

AttributedText _bold(String text, int start, int end) =>
    AttributedText(text)..addAttribution(boldAttribution, SpanRange(start, end));

void main() {
  group('paragraphs', () {
    test('plain', () => expect(_write([_paragraph('Hello')]), 'Hello'));

    test('blocks are separated by a blank line', () {
      expect(_write([_paragraph('a'), _paragraph('b')]), 'a\n\nb');
    });

    test('formatting uses the package inline writer (never stock ¬ underline)', () {
      final text = AttributedText('Hello')..addAttribution(underlineAttribution, const SpanRange(0, 4));
      expect(_write([ParagraphNode(id: '1', text: text)]), '<u>Hello</u>');
    });

    test('line breaks stay on one line', () => expect(_write([_paragraph('a\nb')]), 'a<br>b'));

    test('an empty paragraph is &nbsp;', () {
      expect(_write([_paragraph('a'), _paragraph(''), _paragraph('b')]), 'a\n\n&nbsp;\n\nb');
    });

    test('empty paragraphs are kept wherever they are: blank lines are the writer\'s own', () {
      expect(
        _write([_paragraph(''), _paragraph('a'), _paragraph(''), _paragraph('b'), _paragraph(''), _paragraph('')]),
        '&nbsp;\n\na\n\n&nbsp;\n\nb\n\n&nbsp;\n\n&nbsp;',
      );
    });

    test('a blank page (one empty paragraph) is written as nothing', () {
      expect(_write([_paragraph('')]), '');
    });

    test('a whitespace-only paragraph is written as character references, so it is not a blank line', () {
      expect(_write([_paragraph('  ')]), '&#32;&#32;');
    });
  });

  group('headings', () {
    test('levels 1 and 6', () {
      expect(_write([_paragraph('Title', blockType: header1Attribution)]), '# Title');
      expect(_write([_paragraph('Title', blockType: header6Attribution)]), '###### Title');
    });

    test('# is escaped so a trailing run is not a closing sequence', () {
      expect(_write([_paragraph('C# #', blockType: header2Attribution)]), r'## C\# \#');
    });

    test('empty', () => expect(_write([_paragraph('', blockType: header2Attribution)]), '##'));
  });

  group('quotes and code', () {
    test('a quote with formatting', () {
      expect(
        _write([
          ParagraphNode(
            id: '1',
            text: _bold('Quoted', 0, 5),
            metadata: {NodeMetadata.blockType: blockquoteAttribution},
          ),
        ]),
        '> **Quoted**',
      );
    });

    test('a code block is verbatim, even with formatting and Markdown characters', () {
      final text = _bold('a*b\n<c>', 0, 2);
      expect(
        _write([
          ParagraphNode(id: '1', text: text, metadata: {NodeMetadata.blockType: codeAttribution}),
        ]),
        '```\na*b\n<c>\n```',
      );
    });

    test('the code fence is longer than any backtick run inside', () {
      expect(_write([_paragraph('a\n```\nb', blockType: codeAttribution)]), '````\na\n```\nb\n````');
    });

    test('a code block ignores alignment and indent', () {
      expect(_write([_paragraph('x', blockType: codeAttribution, align: 'center', indent: 2)]), '```\nx\n```');
    });
  });

  group('alignment and indent', () {
    for (final align in ['center', 'right', 'justify']) {
      test('$align paragraph', () {
        expect(_write([_paragraph('Hello', align: align)]), '<div style="text-align:$align">\n\nHello\n\n</div>');
      });
    }

    test('left alignment is the default, so it has no wrapper', () {
      expect(_write([_paragraph('Hello', align: 'left')]), 'Hello');
    });

    test('centered heading', () {
      expect(
        _write([_paragraph('Title', blockType: header1Attribution, align: 'center')]),
        '<div style="text-align:center">\n\n# Title\n\n</div>',
      );
    });

    test('paragraph indent (previously lost on export)', () {
      expect(_write([_paragraph('Hello', indent: 2)]), '<div data-indent="2">\n\nHello\n\n</div>');
    });

    test('a run of list items and tasks sharing an alignment is one wrapper', () {
      Map<String, Object?> align(String value) => {TextNodeMetadata.textAlign: value};
      final markdown = _write([
        ListItemNode.unordered(id: 'a', text: AttributedText('a'), metadata: align('center')),
        ListItemNode.unordered(id: 'b', text: AttributedText('b'), indent: 1, metadata: align('center')),
        TaskNode(id: 'c', text: AttributedText('c'), isComplete: true, metadata: align('center')),
        ListItemNode.ordered(id: 'd', text: AttributedText('d'), metadata: align('right')),
        ListItemNode.ordered(id: 'e', text: AttributedText('e'), metadata: align('left')),
        ListItemNode.ordered(id: 'f', text: AttributedText('f')),
      ]);
      expect(
        markdown,
        '<div style="text-align:center">\n\n- a\n    - b\n- [x] c\n\n</div>\n\n'
        '<div style="text-align:right">\n\n1. d\n\n</div>\n\n'
        '1. e\n1. f',
      );
      expect(_codec.canonicalize(markdown), markdown);
      final nodes = _codec.decodeNodes(markdown);
      expect(
        [for (final node in nodes) node.getMetadataValue(TextNodeMetadata.textAlign)],
        ['center', 'center', 'center', 'right', null, null],
      );
      expect((nodes[1] as ListItemNode).indent, 1);
    });

    test('alignment and indent together, on a quote', () {
      expect(
        _write([_paragraph('Q', blockType: blockquoteAttribution, align: 'right', indent: 1)]),
        '<div style="text-align:right" data-indent="1">\n\n> Q\n\n</div>',
      );
    });
  });

  group('lists and tasks', () {
    test('nested bullet and ordered lists: 4 spaces per level, inline formatting kept', () {
      expect(
        _write([
          ListItemNode.unordered(id: 'l1', text: _bold('Bold bullet', 0, 3)),
          ListItemNode.unordered(id: 'l2', text: AttributedText('Nested bullet'), indent: 1),
          ListItemNode.ordered(id: 'l3', text: AttributedText('Top ordered')),
          ListItemNode.ordered(id: 'l4', text: AttributedText('Nested ordered'), indent: 1),
        ]),
        '- **Bold** bullet\n'
        '    - Nested bullet\n'
        '1. Top ordered\n'
        '    1. Nested ordered',
      );
    });

    test('nested, mixed-completion tasks keep their indent', () {
      expect(
        _write([
          TaskNode(id: 't1', text: AttributedText('Top level'), isComplete: false),
          TaskNode(id: 't2', text: AttributedText('Nested, done'), isComplete: true, indent: 1),
          TaskNode(id: 't3', text: AttributedText('Deeply nested'), isComplete: false, indent: 2),
        ]),
        '- [ ] Top level\n'
        '    - [x] Nested, done\n'
        '        - [ ] Deeply nested',
      );
    });

    test('a list is separated from other blocks by a blank line', () {
      expect(
        _write([_paragraph('a'), ListItemNode.unordered(id: 'l', text: AttributedText('b')), _paragraph('c')]),
        'a\n\n- b\n\nc',
      );
    });

    test('empty items', () {
      expect(
        _write([
          ListItemNode.unordered(id: 'l', text: AttributedText()),
          TaskNode(id: 't', text: AttributedText(), isComplete: false),
        ]),
        '-\n- [ ]',
      );
    });
  });

  group('text that looks like block syntax is escaped at the start of a line', () {
    const cases = {
      '# not a heading': r'\# not a heading',
      '- not a list': r'\- not a list',
      '+ not a list': r'\+ not a list',
      '1. not a list': r'1\. not a list',
      '2) not a list': r'2\) not a list',
      '---': r'\---',
      '=== x': r'\=== x',
      '> not a quote': '&gt; not a quote',
      '```': '&#96;&#96;&#96;',
      '[ ] not a task': r'\[ \] not a task',
      '   - indented': r'   \- indented',
    };
    for (final MapEntry(key: text, value: markdown) in cases.entries) {
      test(text, () => expect(_write([_paragraph(text)]), markdown));
    }

    test('in list items and quotes too', () {
      expect(_write([ListItemNode.unordered(id: 'l', text: AttributedText('- x'))]), r'- \- x');
      expect(_write([_paragraph('1. x', blockType: blockquoteAttribution)]), r'> 1\. x');
    });
  });

  test('horizontal rule', () {
    expect(_write([_paragraph('a'), HorizontalRuleNode(id: 'hr'), _paragraph('b')]), 'a\n\n---\n\nb');
  });
}
