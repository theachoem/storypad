import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_media_embed.dart';
import 'package:storypad/widgets/rich_editor/sp_editor_controller.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';
import 'package:storypad_editor/super_editor.dart';

/// Pages load from and save to Markdown, edited in storypad_editor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  SpEditorController controllerFor(String markdown, {bool readOnly = false}) {
    final controller = SpEditorController(
      markdown: markdown,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: readOnly,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  void type(SpEditorController controller, String text, {int nodeIndex = 1, int offset = 0}) {
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

  test('the converted page starts with its title heading', () {
    expect(storedPage, startsWith('### Trip\n\n**Morning** walk'));
  });

  test('converting drops the empty lines that only spaced a photo out (embeds get space of their own now)', () {
    // The old flow: the title (its own field, spaced from the body), a photo, an empty line for room, then text.
    final page = StoryPageDbModel.legacy(
      id: 2,
      title: 'Title',
      body: [
        {
          'insert': {'image': 'images/1.jpg'},
        },
        {'insert': '\n\nMy other paragraph\n'},
      ],
    );
    expect(page.markdown, '### Title\n\n![](images/1.jpg)\n\nMy other paragraph');
    expect(page.checkConversion().isLossless, isTrue);
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
  });

  group('embeds', () {
    test('insertMedia inserts a full-size photo, as before', () {
      final controller = controllerFor('Hello');
      controller.selection = const TextSelection.collapsed(offset: 5);
      controller.insertMedia(['images/9.jpg']);

      final media = controller.editor.embedsOf(const SpMediaEmbed()).single.$2;
      expect(media, const SpMediaValue(['images/9.jpg'], size: SpEmbedSize.max));
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
      controller.insertAudio('audio/1.m4a');
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
      controller.insertMedia(['images/3.jpg']);
      expect(controller.editor.document.first, isNot(isA<ParagraphNode>()));
      expect(controller.editor.embedsOf(const SpMediaEmbed()).single.$2.paths, ['images/3.jpg']);
    });

    test('an embed inserted with the caret in a title goes below it, so the title stays first', () {
      for (final markdown in ['### Trip', '### Trip\n\nbody']) {
        final controller = controllerFor(markdown);
        controller.selection = const TextSelection.collapsed(offset: 0);
        controller.insertMedia(['images/3.jpg']);
        final page = StoryPageDbModel.markdown(id: 1, markdown: controller.serialize());
        expect(page.markdown, startsWith(markdown.split('\n').first), reason: markdown);
        expect(controller.editor.document.first, isA<ParagraphNode>(), reason: markdown);
        expect(controller.editor.embedsOf(const SpMediaEmbed()).single.$2.paths, ['images/3.jpg']);
      }
    });

    test('an empty title line (where a new page opens) is replaced by the embed, in one undoable edit', () {
      for (final (markdown, placeCaret) in [('###', true), ('', true), ('', false), ('###\n\nbody', true)]) {
        final controller = controllerFor(markdown);
        if (placeCaret) controller.selection = const TextSelection.collapsed(offset: 0);
        controller.insertMedia(['images/3.jpg']);

        final reason = '$markdown, caret: $placeCaret';
        expect(controller.editor.document.first, isNot(isA<ParagraphNode>()), reason: reason);
        expect(controller.serialize(), isNot(startsWith('###')), reason: reason);
        expect(controller.editor.selection.value?.extent.nodeId, controller.editor.document.first.id, reason: reason);

        controller.editor.actions.undo();
        expect(controller.editor.document.first, isA<ParagraphNode>(), reason: reason);
        expect(controller.editor.actions.headingLevel ?? 3, 3, reason: reason);
      }
    });
  });

  group('an empty page', () {
    test('opens for editing on an empty title line, and saves empty while left so', () {
      final controller = controllerFor('');
      expect(controller.editor.document.single, isA<ParagraphNode>());
      expect(controller.editor.actions.headingLevel, isNull, reason: 'no caret yet');
      expect(controller.editor.toMarkdown(), '###');
      expect(controller.serialize(), '');

      controller.selection = const TextSelection.collapsed(offset: 0);
      expect(controller.editor.actions.headingLevel, 3);
      type(controller, 'Trip', nodeIndex: 0);
      expect(StoryPageDbModel.markdown(id: 1, markdown: controller.serialize()).title, 'Trip');
    });

    test('read-only, stays as it is', () {
      expect(controllerFor('', readOnly: true).editor.toMarkdown(), '');
    });
  });

  group('selection, in flat text offsets, and plain text', () {
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
      final controller = SpEditorController(
        markdown: storedPage,
        selection: const TextSelection(baseOffset: 0, extentOffset: 7),
        readOnly: false,
      );
      addTearDown(controller.dispose);
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 7));
    });

    test('plain text', () {
      final controller = controllerFor(storedPage);
      expect(controller.editor.toPlainText(), startsWith('Trip\nMorning walk\ncoffee\nbread'));
      expect(controller.bodyPlainText(), startsWith('Morning walk\ncoffee\nbread'), reason: 'no title');
    });
  });
}
