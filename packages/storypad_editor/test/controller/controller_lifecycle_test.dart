import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';
import '../support/test_embeds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads Markdown and writes it back canonically', () {
    final controller = controllerFor('# Title\n\nHello **world**\n\n<sp-sticker name="cat"></sp-sticker>');

    expect(controller.toMarkdown(), '# Title\n\nHello **world**\n\n<sp-sticker name="cat"></sp-sticker>');
    expect(controller.toPlainText(), 'Title\nHello world\n:cat:');
  });

  test('a trailing embed stays last: the editor adds no line of its own', () {
    final controller = controllerFor('<sp-sticker name="cat"></sp-sticker>');

    expect(controller.document.last, isA<StoryEmbedNode>());
    expect(controller.toMarkdown(), '<sp-sticker name="cat"></sp-sticker>');
  });

  test('empty Markdown is one empty paragraph', () {
    final controller = controllerFor('');
    expect(controller.document.nodeCount, 1);
    expect(controller.toMarkdown(), '');
  });

  test('fromQuill loads through Markdown', () {
    final controller = StoryEditorController.fromQuill([
      {'insert': 'Hi'},
      {
        'insert': '\n',
        'attributes': {'header': 2},
      },
      {
        'insert': {'sticker': 'cat'},
      },
      {'insert': '\n'},
    ], embeds: testEmbeds);
    addTearDown(controller.dispose);

    expect(controller.toMarkdown(), '## Hi\n\n<sp-sticker name="cat"></sp-sticker>');
  });

  test('conflicting embeds are rejected up front', () {
    expect(() => StoryEditorController(embeds: const [StickerEmbedCodec(), StickerEmbedCodec()]), throwsArgumentError);
  });

  group('dirty tracking', () {
    test('non-canonical input is not dirty when opened', () {
      final controller = controllerFor('Title\n=====\n\n\n\n* item');
      expect(controller.isDirty, isFalse);
    });

    test('an edit is dirty; markSaved clears it; undoing back to the saved state is clean', () {
      final controller = controllerFor('Hello');
      selectNode(controller, 0);

      controller.actions.toggleBold();
      expect(controller.isDirty, isTrue);

      controller.actions.undo();
      expect(controller.isDirty, isFalse);

      controller.actions.redo();
      controller.markSaved();
      expect(controller.isDirty, isFalse);
    });
  });

  group('notifications', () {
    test('documentRevision changes on edits, not selection changes', () {
      final controller = controllerFor('Hello');
      final revision = controller.documentRevision.value;

      placeCaret(controller, 0, 1);
      expect(controller.documentRevision.value, revision);

      selectNode(controller, 0);
      controller.actions.toggleItalic();
      expect(controller.documentRevision.value, revision + 1);
    });

    test('documentRevision (and the cached Markdown) follow undo and redo', () {
      final controller = controllerFor('Hello');
      selectNode(controller, 0);
      controller.actions.toggleBold();
      expect(controller.toMarkdown(), '**Hello**');

      final revision = controller.documentRevision.value;
      controller.actions.undo();
      expect(controller.documentRevision.value, greaterThan(revision));
      expect(controller.toMarkdown(), 'Hello');

      controller.actions.redo();
      expect(controller.toMarkdown(), '**Hello**');
    });

    test('the controller notifies on selection, edits, pending styles and read-only changes', () {
      final controller = controllerFor('Hello');
      var notifications = 0;
      controller.addListener(() => notifications++);

      placeCaret(controller, 0, 1);
      final afterSelection = notifications;
      expect(afterSelection, greaterThan(0));

      controller.actions.toggleBold(); // Pending style for the caret.
      expect(notifications, greaterThan(afterSelection));

      final beforeReadOnly = notifications;
      controller.readOnly = true;
      expect(notifications, greaterThan(beforeReadOnly));
    });

    test('lastSelection survives the selection being cleared', () {
      final controller = controllerFor('Hello');
      placeCaret(controller, 0, 2);
      controller.composer.clearSelection();

      expect(controller.selection.value, isNull);
      expect((controller.lastSelection!.extent.nodePosition as TextNodePosition).offset, 2);
    });
  });

  test('editor attachment: re-attaching is harmless, and disposing while attached is caught', () {
    final controller = StoryEditorController(embeds: testEmbeds);
    final editor = Object();
    controller.attachEditor(editor);
    controller.attachEditor(editor);

    expect(controller.dispose, throwsAssertionError);
    controller.detachEditor(editor);
    controller.dispose();
  });
}
