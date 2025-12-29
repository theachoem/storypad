import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/markdown_content_filter_service.dart';

void main() {
  group('MarkdownContentFilterService', () {
    group('Basic Functionality', () {
      test('returns empty string for empty input', () {
        expect(MarkdownContentFilterService.call(''), '');
      });

      test('preserves plain text without markdown', () {
        const text = 'Hello World';
        expect(MarkdownContentFilterService.call(text), text);
      });

      test('preserves multi-line plain text', () {
        const text = 'First line\nSecond line\nThird line';
        expect(MarkdownContentFilterService.call(text), text);
      });
    });

    group('Checkbox Filtering', () {
      test('removes unchecked markdown checkbox markers', () {
        expect(
          MarkdownContentFilterService.call('- [ ] Buy milk'),
          'Buy milk',
        );
      });

      test('removes unchecked emoji checkbox markers', () {
        expect(
          MarkdownContentFilterService.call('⏹️ Buy milk'),
          'Buy milk',
        );
      });

      test('removes checked markdown checkbox markers', () {
        expect(
          MarkdownContentFilterService.call('- [x] Completed task'),
          'Completed task',
        );
      });

      test('removes checked emoji checkbox markers', () {
        expect(
          MarkdownContentFilterService.call('✅ Completed task'),
          'Completed task',
        );
      });

      test('handles multiple checkboxes', () {
        expect(
          MarkdownContentFilterService.call(
            '- [ ] Task 1\n- [x] Task 2\n⏹️ Task 3\n✅ Task 4',
          ),
          'Task 1\nTask 2\nTask 3\nTask 4',
        );
      });

      test('counts only actual task text, not checkbox markers', () {
        const filtered = 'Task description';
        expect(MarkdownContentFilterService.call('- [ ] Task description'), filtered);
        expect(MarkdownContentFilterService.call('⏹️ Task description'), filtered);
        expect(filtered.length, 16); // Only counts actual content
      });
    });

    group('Bullet List Filtering', () {
      test('removes dash bullet markers', () {
        expect(
          MarkdownContentFilterService.call('- Item 1\n- Item 2'),
          'Item 1\nItem 2',
        );
      });

      test('removes asterisk bullet markers', () {
        expect(
          MarkdownContentFilterService.call('* Item 1\n* Item 2'),
          'Item 1\nItem 2',
        );
      });

      test('removes bullet point (•) markers', () {
        expect(
          MarkdownContentFilterService.call('• Item 1\n• Item 2'),
          'Item 1\nItem 2',
        );
      });

      test('preserves dashes inside text content', () {
        expect(
          MarkdownContentFilterService.call('- one-two-three'),
          'one-two-three',
        );
      });
    });

    group('Ordered List Filtering', () {
      test('removes numeric list markers', () {
        expect(
          MarkdownContentFilterService.call('1. First\n2. Second\n10. Tenth'),
          'First\nSecond\nTenth',
        );
      });

      test('removes alphabetic list markers', () {
        expect(
          MarkdownContentFilterService.call('a. First\nb. Second\nc. Third'),
          'First\nSecond\nThird',
        );
      });

      test('removes roman numeral list markers', () {
        expect(
          MarkdownContentFilterService.call('i. First\nii. Second\niii. Third\niv. Fourth'),
          'First\nSecond\nThird\nFourth',
        );
      });

      test('preserves numbers inside text content', () {
        expect(
          MarkdownContentFilterService.call('1. There are 42 items'),
          'There are 42 items',
        );
      });
    });

    group('Markdown Formatting Filtering', () {
      test('removes bold markdown with double asterisks', () {
        expect(
          MarkdownContentFilterService.call('This is **bold** text'),
          'This is bold text',
        );
      });

      test('removes bold markdown with double underscores', () {
        expect(
          MarkdownContentFilterService.call('This is __bold__ text'),
          'This is bold text',
        );
      });

      test('removes italic markdown with single asterisk', () {
        expect(
          MarkdownContentFilterService.call('This is *italic* text'),
          'This is italic text',
        );
      });

      test('removes italic markdown with single underscore', () {
        expect(
          MarkdownContentFilterService.call('This is _italic_ text'),
          'This is italic text',
        );
      });

      test('removes bold+italic markdown with triple asterisks', () {
        expect(
          MarkdownContentFilterService.call('This is ***bold italic*** text'),
          'This is bold italic text',
        );
      });

      test('removes strikethrough markdown', () {
        expect(
          MarkdownContentFilterService.call('This is ~~deleted~~ text'),
          'This is deleted text',
        );
      });

      test('removes inline code backticks', () {
        expect(
          MarkdownContentFilterService.call('Use the `print()` function'),
          'Use the print() function',
        );
      });

      test('removes multiple formatting in same line', () {
        expect(
          MarkdownContentFilterService.call('**Bold** and *italic* and `code`'),
          'Bold and italic and code',
        );
      });

      test('counts only content text, not formatting markers', () {
        const original = '**bold** text';
        const filtered = 'bold text';
        expect(MarkdownContentFilterService.call(original), filtered);
        expect(filtered.length, 9); // Not 13 with markers
      });
    });

    group('Link and Image Filtering', () {
      test('extracts text from markdown links, removes URL', () {
        expect(
          MarkdownContentFilterService.call('[Click here](https://example.com)'),
          'Click here',
        );
      });

      test('removes image syntax entirely (not text content)', () {
        expect(
          MarkdownContentFilterService.call('![alt text](image.jpg)'),
          '',
        );
      });

      test('removes images but preserves surrounding text', () {
        expect(
          MarkdownContentFilterService.call('Before ![img](pic.jpg) after'),
          'Before  after',
        );
      });

      test('preserves link text in mixed content', () {
        expect(
          MarkdownContentFilterService.call('Visit [our site](url) for more'),
          'Visit our site for more',
        );
      });

      test('counts only link text, not URL', () {
        const filtered = 'Google';
        expect(
          MarkdownContentFilterService.call('[Google](https://google.com)'),
          filtered,
        );
        expect(filtered.length, 6); // Not counting URL
      });
    });

    group('Header Filtering', () {
      test('removes header markers (single #)', () {
        expect(
          MarkdownContentFilterService.call('# Heading 1'),
          'Heading 1',
        );
      });

      test('removes header markers (multiple #)', () {
        expect(
          MarkdownContentFilterService.call('### Heading 3'),
          'Heading 3',
        );
      });

      test('removes header markers (max level)', () {
        expect(
          MarkdownContentFilterService.call('###### Heading 6'),
          'Heading 6',
        );
      });

      test('preserves # symbols inside text', () {
        expect(
          MarkdownContentFilterService.call('## Issue #42'),
          'Issue #42',
        );
      });
    });

    group('Blockquote Filtering', () {
      test('removes single blockquote marker', () {
        expect(
          MarkdownContentFilterService.call('> quoted text'),
          'quoted text',
        );
      });

      test('removes nested blockquote markers', () {
        expect(
          MarkdownContentFilterService.call('> > nested quote'),
          'nested quote',
        );
      });

      test('removes triple nested blockquote markers', () {
        expect(
          MarkdownContentFilterService.call('> > > deep quote'),
          'deep quote',
        );
      });
    });

    group('Code Block Filtering', () {
      test('removes code block markers', () {
        expect(
          MarkdownContentFilterService.call('```\ncode here\n```'),
          'code here',
        );
      });

      test('preserves code content', () {
        expect(
          MarkdownContentFilterService.call('```\nconst x = 5;\n```'),
          'const x = 5;',
        );
      });
    });

    group('Horizontal Rule Filtering', () {
      test('removes horizontal rule with dashes', () {
        expect(
          MarkdownContentFilterService.call('---'),
          '',
        );
      });

      test('removes horizontal rule with asterisks', () {
        expect(
          MarkdownContentFilterService.call('***'),
          '',
        );
      });

      test('removes horizontal rule with underscores', () {
        expect(
          MarkdownContentFilterService.call('___'),
          '',
        );
      });

      test('removes horizontal rule between paragraphs', () {
        expect(
          MarkdownContentFilterService.call('First\n---\nSecond'),
          'First\nSecond',
        );
      });

      test('counts only text, not horizontal rules', () {
        const text = 'First\n---\nSecond';
        final filtered = MarkdownContentFilterService.call(text);
        expect(filtered, 'First\nSecond');
        // 'First\nSecond' has 12 characters total
        expect(filtered.replaceAll('\n', ' ').trim().length, 12); // "First Second" with space
      });
    });

    group('Indentation Filtering', () {
      test('removes leading tabs', () {
        expect(
          MarkdownContentFilterService.call('\tIndented line'),
          'Indented line',
        );
      });

      test('removes multiple leading tabs', () {
        expect(
          MarkdownContentFilterService.call('\t\t\tDeep indent'),
          'Deep indent',
        );
      });

      test('preserves tabs inside content', () {
        expect(
          MarkdownContentFilterService.call('\tColumn1\tColumn2'),
          'Column1\tColumn2',
        );
      });
    });

    group('Embedded Widget Filtering', () {
      test('removes object replacement character (widget placeholder)', () {
        expect(
          MarkdownContentFilterService.call('Before \uFFFC after'),
          'Before  after',
        );
      });

      test('removes multiple widget placeholders', () {
        expect(
          MarkdownContentFilterService.call('\uFFFC text \uFFFC'),
          ' text ', // Spaces remain
        );
      });

      test('counts only text, not widget markers', () {
        const filtered = 'Hello  world'; // Double space where widget was
        expect(
          MarkdownContentFilterService.call('Hello \uFFFC world'),
          filtered,
        );
        expect(filtered.length, 12);
      });
    });

    group('Complex Mixed Content', () {
      test('filters complex markdown with multiple element types', () {
        const markdown = '''
# Title
- [ ] Task 1
- [x] Task 2
**Bold** and *italic*
[Link](url)
> Quote
---
1. Item''';
        const expected = 'Title\nTask 1\nTask 2\nBold and italic\nLink\nQuote\nItem';
        expect(MarkdownContentFilterService.call(markdown), expected);
      });

      test('filters nested structures', () {
        expect(
          MarkdownContentFilterService.call('\t- **Item** with *formatting*'),
          'Item with formatting',
        );
      });

      test('preserves actual content in complex scenario', () {
        const markdown = '## Story\n\n- [ ] Write **introduction**\n- Research [topic](url)\n\n> Get started!';
        final filtered = MarkdownContentFilterService.call(markdown);
        expect(filtered, contains('Story'));
        expect(filtered, contains('Write introduction'));
        expect(filtered, contains('Research topic'));
        expect(filtered, contains('Get started!'));
        expect(filtered, isNot(contains('##')));
        expect(filtered, isNot(contains('**')));
        expect(filtered, isNot(contains('- [ ]')));
        expect(filtered, isNot(contains('>')));
      });

      test('ensures accurate character count for user content', () {
        // User writes: "Hello World" with bold formatting
        const withMarkdown = '**Hello World**';
        String filtered = MarkdownContentFilterService.call(withMarkdown);
        expect(filtered, 'Hello World');
        expect(filtered.length, 11); // Not 15 with ** markers
      });

      test('ensures accurate word count for user content', () {
        // User writes a list with 3 items
        const withMarkdown = '- Item one\n- Item two\n- Item three';
        final filtered = MarkdownContentFilterService.call(withMarkdown);
        final words = filtered.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        expect(words, 6); // "Item one Item two Item three" = 6 words
      });
    });

    group('Empty Lines and Whitespace', () {
      test('removes lines that become empty after filtering', () {
        expect(
          MarkdownContentFilterService.call('Text\n---\n\t\nMore text'),
          'Text\nMore text',
        );
      });

      test('removes empty lines after filtering', () {
        // Blank lines become empty after filtering and are removed
        expect(
          MarkdownContentFilterService.call('Para 1\n\nPara 2'),
          'Para 1\nPara 2',
        );
      });
    });

    group('Edge Cases', () {
      test('handles markdown markers without content', () {
        expect(MarkdownContentFilterService.call('****'), '');
        expect(MarkdownContentFilterService.call('- '), '');
        expect(MarkdownContentFilterService.call('## '), '');
      });

      test('handles unclosed markdown syntax', () {
        expect(
          MarkdownContentFilterService.call('**bold without close'),
          '**bold without close',
        );
      });

      test('handles special characters in content', () {
        const text = 'Special chars: @#\$%^&*()';
        expect(MarkdownContentFilterService.call(text), text);
      });

      test('handles unicode characters', () {
        const text = 'Unicode: 你好 مرحبا שלום';
        expect(MarkdownContentFilterService.call(text), text);
      });

      test('handles emoji in content (not structural emoji)', () {
        const text = 'Happy 😊 day';
        expect(MarkdownContentFilterService.call(text), text);
      });
    });
  });
}
