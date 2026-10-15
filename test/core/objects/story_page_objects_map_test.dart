import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad_editor/super_editor.dart';

/// An edit only marks its page; the page's Markdown is read from its editor when the content is next read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StoryPageObjectsMap pagesMap;
  late StoryContentDbModel content;

  setUp(() {
    content = StoryContentDbModel.create(createdAt: DateTime(2026)).withPages([
      StoryPageDbModel.markdown(id: 1, markdown: '### Trip\n\nHello'),
      StoryPageDbModel.markdown(id: 2, markdown: 'Second'),
    ]);
    pagesMap = StoryPageObjectsMap();
    for (final page in content.richPages!) {
      pagesMap.add(richPage: page, readOnly: false);
    }
  });

  tearDown(() => pagesMap.dispose());

  void type(int pageId, String text) {
    final editor = pagesMap[pageId]!.bodyController.editor;
    editor.actions.placeCaretAtEnd();
    editor.editor.execute([InsertPlainTextAtCaretRequest(text)]);
  }

  test('without an edit, the content is returned as is', () {
    expect(identical(pagesMap.withPendingEdits(content), content), isTrue);
  });

  test('an edited page is read from its editor, once', () {
    type(1, ' there');
    final edited = pagesMap.withPendingEdits(content);
    expect(edited.richPages!.first.markdown, '### Trip\n\nHello there');
    expect(edited.richPages!.last.markdown, 'Second');
    expect(edited.title, 'Trip');
    expect(edited.plainText, contains('there'));
    expect(pagesMap[1]!.page.markdown, '### Trip\n\nHello there');
    expect(pagesMap[1]!.hasPendingEdit, isFalse);

    expect(identical(pagesMap.withPendingEdits(edited), edited), isTrue, reason: 'read once');
  });

  test('an edit counts even when nothing marked it (its editor off screen, edited from the toolbar)', () {
    type(2, '!');
    expect(pagesMap[2]!.hasPendingEdit, isTrue);
    expect(pagesMap[1]!.hasPendingEdit, isFalse);
    expect(pagesMap.withPendingEdits(content).richPages!.last.markdown, 'Second!');
  });

  test('reading the page first (e.g. its title) still leaves the edit for the content', () {
    type(2, '!');
    expect(pagesMap[2]!.page.markdown, 'Second!');
    expect(pagesMap.withPendingEdits(content).richPages!.last.markdown, 'Second!');
  });
}
