import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/rich_text/rich_text_adapter.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/embed_attributes.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/media_embed.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_adapter.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_controller.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';
import 'package:storypad_editor/super_editor.dart';

/// Pages load from and save to Markdown, edited in storypad_editor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final adapter = StoryPadEditorRichTextAdapter();

  // A realistic page from before Markdown: formatting, a list, an embed with attributes, a legacy key, an unknown
  // embed -- converted the way opening a story converts it.
  final legacyPage = StoryPageDbModel.legacy(
    id: 1,
    title: 'Trip',
    body: [
      {
        'insert': 'Morning',
        'attributes': {'bold': true},
      },
      {'insert': ' walk\n'},
      {'insert': 'coffee'},
      {
        'insert': '\n',
        'attributes': {'list': 'checked'},
      },
      {'insert': 'bread'},
      {
        'insert': '\n',
        'attributes': {'list': 'unchecked', 'indent': 1},
      },
      {
        'insert': {'image': 'images/1.jpg|images/2.jpg'},
        'attributes': {'custom-embed-size': 'default'},
      },
      {'insert': '\n'},
      {
        'insert': {'sticker': 'party.png'},
      },
      {'insert': '\nThe end\n'},
    ],
  );
  final storedPage = legacyPage.toMarkdownPage().markdown;

  StoryPadEditorRichTextController controllerFor(String markdown, {bool readOnly = false}) {
    final controller = adapter.createController(
      markdown: markdown,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: readOnly,
    );
    addTearDown(controller.dispose);
    return controller as StoryPadEditorRichTextController;
  }

  void type(StoryPadEditorRichTextController controller, String text, {int nodeIndex = 1, int offset = 0}) {
    final node = controller.editor.document.getNodeAt(nodeIndex)!;
    controller.editor.editor.execute([
      InsertTextRequest(
        documentPosition: DocumentPosition(
          nodeId: node.id,
          nodePosition: TextNodePosition(offset: offset),
        ),
        textToInsert: text,
        attributions: {},
      ),
    ]);
  }

  test('the app edits with storypad_editor', () {
    expect(editorAdapter, isA<StoryPadEditorRichTextAdapter>());
  });

  test('the converted page starts with its title heading', () {
    expect(storedPage, startsWith('### Trip\n\n**Morning** walk'));
  });

  group('saving', () {
    test('an unedited page saves its original Markdown, untouched', () {
      final controller = controllerFor(storedPage);
      expect(identical(controller.serialize(), storedPage), isTrue);

      // So a story opened and closed without edits isn't a change (drafts, "revert if nothing changed").
      final page = StoryPageDbModel.markdown(id: 1, markdown: storedPage);
      final content = StoryContentDbModel.create().copyWith(richPages: [page]);
      final reopened = content.copyWith(richPages: [page.withMarkdown(controller.serialize())]);
      expect(reopened.hasChanges(content), isFalse);
    });

    test('an edit saves Markdown with the edit, readable by everything that reads stories', () {
      final controller = controllerFor(storedPage);
      type(controller, 'Sunny ');

      final saved = StoryPageDbModel.markdown(id: 1, markdown: controller.serialize());
      expect(saved.markdown, isNot(storedPage));
      expect(saved.title, 'Trip');
      expect(QuillDeltaToPlainTextService.call(saved.quillBody, markdown: false), contains('Sunny Morning walk'));
      // The unknown embed survives verbatim; the album is written back under the current key.
      expect(
        saved.quillBody,
        contains(
          equals({
            'insert': {'sticker': 'party.png'},
          }),
        ),
      );
      expect(
        saved.quillBody,
        contains(
          equals({
            'insert': {'media': 'images/1.jpg|images/2.jpg'},
          }),
        ),
      );
    });

    test('editing the title heading changes the page title', () {
      final controller = controllerFor(storedPage);
      type(controller, 'Beach ', nodeIndex: 0);
      expect(StoryPageDbModel.markdown(id: 1, markdown: controller.serialize()).title, 'Beach Trip');
    });

    test('undoing every edit gets the original Markdown back', () {
      final controller = controllerFor(storedPage);
      type(controller, 'x');
      expect(controller.serialize(), isNot(storedPage));

      controller.editor.actions.undo();
      expect(identical(controller.serialize(), storedPage), isTrue);
    });

    test('a checkbox toggled while read-only is saved', () {
      final controller = controllerFor(storedPage, readOnly: true);
      final task = controller.editor.document.whereType<TaskNode>().first;
      controller.editor.editor.execute([ChangeTaskCompletionRequest(nodeId: task.id, isComplete: false)]);

      expect(controller.serialize(), contains('- [ ] coffee'));
    });

    test('notifies on content changes, not on selection changes', () {
      final controller = controllerFor(storedPage);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.selection = const TextSelection.collapsed(offset: 3);
      expect(notified, 0);
      type(controller, 'x');
      expect(notified, 1);
    });
  });

  group('embeds', () {
    test('insertMedia inserts a full-size photo, as before', () {
      final controller = controllerFor('Hello');
      controller.selection = const TextSelection.collapsed(offset: 5);
      adapter.insertMedia(controller: controller, mediaPath: 'images/9.jpg');

      final media = controller.editor.embedsOf(const MediaEmbed()).single.$2;
      expect(media, const MediaValue(['images/9.jpg'], size: EmbedSize.max));
      expect(
        StoryPageDbModel.markdown(id: 1, markdown: controller.serialize()).quillBody,
        contains(
          equals({
            'insert': {'media': 'images/9.jpg'},
            'attributes': {'custom-embed-size': 'max'},
          }),
        ),
      );
    });

    test('insertAudio', () {
      final controller = controllerFor('');
      adapter.insertAudio(controller: controller, audioPath: 'audio/1.m4a');
      expect(
        StoryPageDbModel.markdown(id: 1, markdown: controller.serialize()).quillBody,
        contains(
          equals({
            'insert': {'audio': 'audio/1.m4a'},
          }),
        ),
      );
    });

    test('an embed at a placed caret goes there (a story started from a photo)', () {
      final controller = controllerFor('Hello');
      controller.selection = const TextSelection.collapsed(offset: 0);
      controller.insertEmbed(embedType: 'media', value: 'images/3.jpg');
      expect(controller.editor.document.first, isNot(isA<ParagraphNode>()));
      expect(controller.editor.embedsOf(const MediaEmbed()).single.$2.paths, ['images/3.jpg']);
    });

    test('an embed inserted with the caret in the title goes below it, so the title stays first', () {
      for (final markdown in ['###', '### Trip', '### Trip\n\nbody']) {
        final controller = controllerFor(markdown);
        controller.selection = const TextSelection.collapsed(offset: 0);
        controller.insertEmbed(embedType: 'media', value: 'images/3.jpg');
        final page = StoryPageDbModel.markdown(id: 1, markdown: controller.serialize());
        expect(page.markdown, startsWith(markdown.split('\n').first), reason: markdown);
        expect(controller.editor.document.first, isA<ParagraphNode>(), reason: markdown);
        expect(controller.editor.embedsOf(const MediaEmbed()).single.$2.paths, ['images/3.jpg']);
      }
    });

    test('an embed key no embed imports is ignored, not inserted as garbage', () {
      final controller = controllerFor('');
      controller.insertEmbed(embedType: 'nope', value: 'x');
      expect(controller.serialize(), isEmpty);
    });
  });

  group('selection and document, in Quill-style offsets', () {
    test('offsets round-trip, across text and embeds', () {
      final controller = controllerFor(storedPage);
      for (final selection in const [
        TextSelection.collapsed(offset: 0),
        TextSelection(baseOffset: 2, extentOffset: 20),
        TextSelection.collapsed(offset: 32),
        TextSelection.collapsed(offset: 34),
      ]) {
        controller.selection = selection;
        expect(controller.selection, selection);
      }
    });

    test('a selection handed over from another controller (show → edit) is kept', () {
      final controller = adapter.createController(
        markdown: storedPage,
        selection: const TextSelection(baseOffset: 0, extentOffset: 7),
        readOnly: false,
      );
      addTearDown(controller.dispose);
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 7));
    });

    test('plain text', () {
      final controller = controllerFor(storedPage);
      expect(controller.document.toPlainText(), startsWith('Trip\nMorning walk\ncoffee\nbread'));
      expect(controller.document.bodyPlainText(), startsWith('Morning walk\ncoffee\nbread'), reason: 'no title');
    });
  });
}
