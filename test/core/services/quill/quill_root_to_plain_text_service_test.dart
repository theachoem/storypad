import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('widget test that might involve painters', (WidgetTester tester) async {
    group('QuillRootToPlainTextService', () {
      test('plain text', () {
        final doc = Document.fromDelta(Delta()..insert('Hello world\n'));
        expect(QuillRootToPlainTextService.call(doc.root), 'Hello world\n');
      });

      test('bold and italic', () {
        final doc = Document.fromDelta(Delta()
          ..insert('BoldItalic', {'bold': true, 'italic': true})
          ..insert('\n'));
        expect(QuillRootToPlainTextService.call(doc.root), '***BoldItalic***\n');
      });

      test('bullet list with indent', () {
        final doc = Document.fromDelta(Delta()
          ..insert('Item 1')
          ..insert('\n', {'list': 'bullet'})
          ..insert('Item 2')
          ..insert('\n', {'list': 'bullet', 'indent': 1}));
        expect(
          QuillRootToPlainTextService.call(doc.root),
          '- Item 1\n\t- Item 2\n',
        );
      });

      test('ordered list with indent', () {
        final doc = Document.fromDelta(Delta()
          ..insert('First')
          ..insert('\n', {'list': 'ordered'})
          ..insert('Second')
          ..insert('\n', {'list': 'ordered', 'indent': 1}));
        expect(
          QuillRootToPlainTextService.call(doc.root),
          '1. First\n\t1. Second\n',
        );
      });

      test('blockquote', () {
        final doc = Document.fromDelta(Delta()
          ..insert('Quote this')
          ..insert('\n', {'blockquote': true}));
        expect(
          QuillRootToPlainTextService.call(doc.root),
          '> Quote this\n',
        );
      });

      test('code block', () {
        final doc = Document.fromDelta(Delta()
          ..insert('print("hi")')
          ..insert('\n', {'code-block': true}));
        expect(
          QuillRootToPlainTextService.call(doc.root),
          '```\nprint("hi")\n```\n',
        );
      });

      test('checked and unchecked checklist', () {
        final doc = Document.fromDelta(Delta()
          ..insert('Done')
          ..insert('\n', {'list': 'checked'})
          ..insert('Todo')
          ..insert('\n', {'list': 'unchecked'}));
        expect(
          QuillRootToPlainTextService.call(doc.root),
          '- [x] Done\n- [ ] Todo\n',
        );
      });
    });
  });
}
