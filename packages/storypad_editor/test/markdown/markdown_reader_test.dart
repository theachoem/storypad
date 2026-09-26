import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

final _codec = StoryCodec();

List<DocumentNode> _read(String markdown) => _codec.decodeNodes(markdown);

T _single<T extends DocumentNode>(String markdown) {
  final nodes = _read(markdown);
  expect(nodes, hasLength(1), reason: 'nodes: $nodes');
  return nodes.single as T;
}

Attribution? _blockType(DocumentNode node) => node.getMetadataValue(NodeMetadata.blockType);

void main() {
  test('empty input reads as one empty paragraph', () {
    expect(_single<ParagraphNode>('').text.toPlainText(), '');
    expect(_single<ParagraphNode>('\n\n  \n').text.toPlainText(), '');
  });

  group('paragraphs', () {
    test('lines of one paragraph are joined with line breaks', () {
      expect(_single<ParagraphNode>('a\nb\\\nc<br>d').text.toPlainText(), 'a\nb\nc\nd');
    });

    test('a blank line separates paragraphs', () {
      expect(_read('a\n\nb').map((node) => (node as ParagraphNode).text.toPlainText()), ['a', 'b']);
    });

    test('&nbsp; is an empty paragraph', () {
      final nodes = _read('a\n\n&nbsp;\n\n&nbsp;\n\nb');
      expect(nodes.map((node) => (node as ParagraphNode).text.toPlainText()), ['a', '', '', 'b']);
    });

    test('leading spaces are kept', () {
      expect(_single<ParagraphNode>('   a').text.toPlainText(), '   a');
    });
  });

  group('headings', () {
    test('levels', () {
      for (var level = 1; level <= 6; level++) {
        final node = _single<ParagraphNode>('${'#' * level} Title');
        expect(node.text.toPlainText(), 'Title');
        expect(_blockType(node), NamedAttribution('header$level'));
      }
    });

    test('an optional closing sequence is removed; escaped hashes are text', () {
      expect(_single<ParagraphNode>('## Title ##').text.toPlainText(), 'Title');
      expect(_single<ParagraphNode>(r'## C\# \#').text.toPlainText(), 'C# #');
    });

    test('#hashtag is a paragraph', () {
      expect(_blockType(_single<ParagraphNode>('#hashtag')), paragraphAttribution);
    });
  });

  group('code', () {
    test('fenced with backticks or tildes, verbatim', () {
      final node = _single<ParagraphNode>('```\na*b\n  <c>\n```');
      expect(node.text.toPlainText(), 'a*b\n  <c>');
      expect(_blockType(node), codeAttribution);

      expect(_single<ParagraphNode>('~~~dart\nx\n~~~').text.toPlainText(), 'x');
    });

    test('a longer fence can hold a shorter one', () {
      expect(_single<ParagraphNode>('````\n```\n````').text.toPlainText(), '```');
    });

    test('an unclosed fence runs to the end', () {
      expect(_single<ParagraphNode>('```\na\nb').text.toPlainText(), 'a\nb');
    });
  });

  group('quotes', () {
    test('consecutive quote lines are one quote', () {
      final node = _single<ParagraphNode>('> a\n> **b**\n>');
      expect(node.text.toPlainText(), 'a\nb\n');
      expect(_blockType(node), blockquoteAttribution);
    });
  });

  group('lists and tasks', () {
    test('4-space nesting (canonical)', () {
      final nodes = _read('- a\n    - b\n        1. c');
      expect(nodes.map((node) => (node as ListItemNode).indent), [0, 1, 2]);
      expect((nodes[2] as ListItemNode).type, ListItemType.ordered);
    });

    test('2- and 3-space nesting (hand-written)', () {
      expect(_read('- a\n  - b').map((node) => (node as ListItemNode).indent), [0, 1]);
      expect(_read('1. a\n   1. b').map((node) => (node as ListItemNode).indent), [0, 1]);
    });

    test('nested tasks keep their indent and completion (stock super_editor drops both)', () {
      final nodes = _read('- [ ] a\n    - [x] b\n        - [X] c').cast<TaskNode>();
      expect(nodes.map((node) => node.indent), [0, 1, 2]);
      expect(nodes.map((node) => node.isComplete), [false, true, true]);
      expect(nodes.map((node) => node.text.toPlainText()), ['a', 'b', 'c']);
    });

    test('a task can be indented without a parent (free task indent)', () {
      expect(_single<TaskNode>('        - [ ] orphan').indent, 2);
    });

    test('indent is capped', () {
      expect(_single<ListItemNode>('${' ' * 400}- deep').indent, 6);
    });

    test('continuation lines join the item', () {
      expect(_single<ListItemNode>('- a\n  b').text.toPlainText(), 'a\nb');
    });

    test('empty items', () {
      expect(_single<ListItemNode>('-').text.toPlainText(), '');
      expect(_single<TaskNode>('- [ ]').text.toPlainText(), '');
    });

    test('**bold** at the start of a line is not a list item', () {
      expect(_single<ParagraphNode>('**b** x').text.toPlainText(), 'b x');
    });
  });

  test('thematic breaks', () {
    for (final line in ['---', '***', '___', '- - -', ' * * * ']) {
      expect(_single<DocumentNode>(line), isA<HorizontalRuleNode>(), reason: line);
    }
  });

  group('alignment/indent wrapper', () {
    test('a centered paragraph', () {
      final node = _single<ParagraphNode>('<div style="text-align:center">\n\nHello\n\n</div>');
      expect(node.text.toPlainText(), 'Hello');
      expect(node.getMetadataValue(TextNodeMetadata.textAlign), 'center');
    });

    test('a centered heading keeps its heading type', () {
      final node = _single<ParagraphNode>('<div style="text-align:center">\n\n## Title\n\n</div>');
      expect(_blockType(node), header2Attribution);
      expect(node.getMetadataValue(TextNodeMetadata.textAlign), 'center');
    });

    test('indent, with inline formatting inside', () {
      final node = _single<ParagraphNode>('<div data-indent="3">\n\n**Bold** text\n\n</div>');
      expect(node.indent, 3);
      expect(node.text.getAllAttributionsAt(0), contains(boldAttribution));
    });

    test('an unrecognized style is ignored', () {
      expect(_single<ParagraphNode>('<div style="color:red">\n\nx\n\n</div>').getMetadataValue('textAlign'), isNull);
    });

    test('without a closing tag it is text, and does not swallow the rest of the document', () {
      final nodes = _read('<div style="text-align:center">\n\na\n\nb');
      expect(nodes.map((node) => (node as ParagraphNode).text.toPlainText()), [
        '<div style="text-align:center">',
        'a',
        'b',
      ]);
    });
  });

  test('inline HTML formatting inside blocks', () {
    final node = _single<ParagraphNode>('<span style="color:#336699ff">Hello</span>');
    expect(
      node.text.getAllAttributionsAt(0).whereType<ColorAttribution>().single.color,
      const Color.fromARGB(0xff, 0x33, 0x66, 0x99),
    );
  });
}
