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

  test('hasPendingEdits tells a closing editor there is an edit left to save, until the content takes it', () {
    expect(pagesMap.hasPendingEdits, isFalse);
    // From the toolbar, with the page off screen: nothing marked it, and no save was started.
    type(2, '!');
    expect(pagesMap.hasPendingEdits, isTrue);
    pagesMap.withPendingEdits(content);
    expect(pagesMap.hasPendingEdits, isFalse, reason: 'a save (or a discard, which saves first) took it');
  });

  test('every page reports its edits, on screen or not, pages added later too', () {
    var reported = 0;
    pagesMap.onEdited = () => reported++;

    type(2, '!');
    expect(reported, greaterThan(0));

    pagesMap.add(richPage: StoryPageDbModel.markdown(id: 3, markdown: 'Third'), readOnly: false);
    reported = 0;
    type(3, '!');
    expect(reported, greaterThan(0));

    // Removed (and disposed) without a report; the pages left still report.
    pagesMap.remove(3);
    reported = 0;
    type(1, '!');
    expect(reported, greaterThan(0));
  });

  test('a page from before Markdown stays as stored after an edit that was undone', () {
    final legacy = StoryPageDbModel.legacy(
      id: 9,
      title: 'Old',
      body: [
        {'insert': 'Quill body\n'},
      ],
    );
    final legacyContent = StoryContentDbModel.create(createdAt: DateTime(2026)).withPages([legacy]);
    final stored = legacyContent.richPages!.single;
    final legacyMap = StoryPageObjectsMap()..add(richPage: stored, readOnly: false);
    addTearDown(legacyMap.dispose);

    final editor = legacyMap[9]!.bodyController.editor;
    editor.actions.placeCaretAtEnd();
    editor.editor.execute([const InsertPlainTextAtCaretRequest('!')]);
    editor.actions.undo();

    final page = legacyMap.withPendingEdits(legacyContent).richPages!.single;
    expect(page.isLegacy, isTrue);
    expect(page.toJson(), stored.toJson());

    // A real edit is written as Markdown.
    editor.actions.placeCaretAtEnd();
    editor.editor.execute([const InsertPlainTextAtCaretRequest('!')]);
    expect(legacyMap.withPendingEdits(legacyContent).richPages!.single.isLegacy, isFalse);
  });

  test('reading the page first (e.g. its title) still leaves the edit for the content', () {
    type(2, '!');
    expect(pagesMap[2]!.page.markdown, 'Second!');
    expect(pagesMap.withPendingEdits(content).richPages!.last.markdown, 'Second!');
  });
}
