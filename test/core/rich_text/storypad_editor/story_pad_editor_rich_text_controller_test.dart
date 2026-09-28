import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/rich_text/rich_text_adapter.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/embed_attributes.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/media_embed.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_adapter.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_controller.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_embeds.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';
import 'package:storypad_editor/super_editor.dart';

/// The bridge: pages load from and save to Quill Delta, edited in storypad_editor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final adapter = StoryPadEditorRichTextAdapter();

  // A realistic stored page: formatting, a list, an embed with attributes, a legacy key, an unknown embed.
  final storedPage = <dynamic>[
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
  ];

  StoryPadEditorRichTextController controllerFor(List<dynamic> json, {bool readOnly = false}) {
    final controller = adapter.createController(
      json: json,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: readOnly,
    );
    addTearDown(controller.dispose);
    return controller as StoryPadEditorRichTextController;
  }

  void type(StoryPadEditorRichTextController controller, String text, {int nodeIndex = 0, int offset = 0}) {
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

  group('saving', () {
    test('an unedited page saves its original JSON, untouched', () {
      final controller = controllerFor(storedPage);
      expect(identical(controller.serialize(), storedPage), isTrue);

      // So a story opened and closed without edits isn't a change (drafts, "revert if nothing changed").
      final page = StoryPageDbModel(id: 1, title: 'Title', body: storedPage);
      final content = StoryContentDbModel.create().copyWith(richPages: [page]);
      final reopened = content.copyWith(richPages: [page.copyWith(body: controller.serialize())]);
      expect(reopened.hasChanges(content), isFalse);
    });

    test('an edit saves Quill with the edit, readable by everything that reads stories', () {
      final controller = controllerFor(storedPage);
      type(controller, 'Sunny ');

      final saved = controller.serialize();
      expect(saved, isNot(storedPage));
      expect(saved.last, {'insert': '\nThe end\n'});
      expect(QuillDeltaToPlainTextService.call(saved, markdown: false), contains('Sunny Morning walk'));
      // The unknown embed survives verbatim; the album is written back under the current key.
      expect(
        saved,
        contains(
          equals({
            'insert': {'sticker': 'party.png'},
          }),
        ),
      );
      expect(
        saved,
        contains(
          equals({
            'insert': {'media': 'images/1.jpg|images/2.jpg'},
          }),
        ),
      );
      expect(storyPadCodec.markdownToQuill(storyPadCodec.quillToMarkdown(saved)), saved);
    });

    test('undoing every edit gets the original JSON back', () {
      final controller = controllerFor(storedPage);
      type(controller, 'x');
      expect(controller.serialize(), isNot(same(storedPage)));

      controller.editor.actions.undo();
      expect(identical(controller.serialize(), storedPage), isTrue);
    });

    test('a checkbox toggled while read-only is saved', () {
      final controller = controllerFor(storedPage, readOnly: true);
      final task = controller.editor.document.whereType<TaskNode>().first;
      controller.editor.editor.execute([ChangeTaskCompletionRequest(nodeId: task.id, isComplete: false)]);

      expect(
        controller.serialize(),
        contains(
          equals({
            'insert': '\n',
            'attributes': {'list': 'unchecked'},
          }),
        ),
      );
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
      final controller = controllerFor([
        {'insert': 'Hello\n'},
      ]);
      controller.selection = const TextSelection.collapsed(offset: 5);
      adapter.insertMedia(controller: controller, mediaPath: 'images/9.jpg');

      final media = controller.editor.embedsOf(const MediaEmbed()).single.$2;
      expect(media, const MediaValue(['images/9.jpg'], size: EmbedSize.max));
      expect(
        controller.serialize(),
        contains(
          equals({
            'insert': {'media': 'images/9.jpg'},
            'attributes': {'custom-embed-size': 'max'},
          }),
        ),
      );
    });

    test('insertAudio', () {
      final controller = controllerFor([]);
      adapter.insertAudio(controller: controller, audioPath: 'audio/1.m4a');
      expect(
        controller.serialize(),
        contains(
          equals({
            'insert': {'audio': 'audio/1.m4a'},
          }),
        ),
      );
    });

    test('replaceText with an embed map inserts it at that offset (a story started from a photo)', () {
      final controller = controllerFor([]);
      controller.replaceText(0, 0, {'media': 'images/3.jpg'}, null);
      expect(controller.editor.embedsOf(const MediaEmbed()).single.$2.paths, ['images/3.jpg']);
    });

    test('an embed key no embed imports is ignored, not inserted as garbage', () {
      final controller = controllerFor([]);
      controller.insertEmbed(embedType: 'nope', value: 'x');
      expect(controller.serialize(), isEmpty);
    });

    test('replaceEmbed keeps the embed\'s other properties', () {
      final controller = controllerFor([
        {
          'insert': {'media': 'images/1.jpg'},
          'attributes': {'custom-embed-alignment': 'center'},
        },
        {'insert': '\n'},
      ]);
      controller.replaceEmbed(offset: 0, length: 1, embedType: 'media', value: 'images/1.jpg|images/2.jpg');
      expect(
        controller.editor.embedsOf(const MediaEmbed()).single.$2,
        const MediaValue(['images/1.jpg', 'images/2.jpg'], alignment: EmbedAlignment.center),
      );
    });
  });

  group('selection and document, in Quill-style offsets', () {
    test('offsets round-trip, across text and embeds', () {
      final controller = controllerFor(storedPage);
      for (final selection in const [
        TextSelection.collapsed(offset: 0),
        TextSelection(baseOffset: 2, extentOffset: 20),
        TextSelection.collapsed(offset: 27),
        TextSelection.collapsed(offset: 29),
      ]) {
        controller.selection = selection;
        expect(controller.selection, selection);
      }
    });

    test('a selection handed over from another controller (show → edit) is kept', () {
      final controller = adapter.createController(
        json: storedPage,
        selection: const TextSelection(baseOffset: 0, extentOffset: 7),
        readOnly: false,
      );
      addTearDown(controller.dispose);
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 7));
    });

    test('plain text and length', () {
      final controller = controllerFor(storedPage);
      expect(controller.document.toPlainText(), startsWith('Morning walk\ncoffee\nbread'));
      expect(
        controller.document.length,
        controller.editor.document.fold(0, (sum, node) {
          return sum + (node is TextNode ? node.text.length : 1) + 1;
        }),
      );
      expect(controller.document.toJson(), same(storedPage));
    });

    test('cursor left/right move one character', () {
      final controller = controllerFor([
        {'insert': 'abc\n'},
      ]);
      controller.selection = const TextSelection.collapsed(offset: 1);
      controller.moveCursorRight();
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      controller.moveCursorLeft();
      controller.moveCursorLeft();
      expect(controller.selection, const TextSelection.collapsed(offset: 0));
    });
  });

  test('headless documents read stored pages', () {
    final document = adapter.createDocument(json: storedPage);
    expect(document.toPlainText(), startsWith('Morning walk'));
    expect(document.toJson(), same(storedPage));
    expect(adapter.createEmptyDocument().toPlainText(), '');
  });
}
