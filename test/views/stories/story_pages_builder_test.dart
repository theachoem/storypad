import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_builder.dart';
import 'package:storypad/widgets/rich_editor/sp_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// The keyboard's animation changes the MediaQuery on every frame: it must not rebuild the pages' editors.
void main() {
  for (final layoutType in PageLayoutType.values) {
    testWidgets('${layoutType.name}: the keyboard moves only the bottom space, never rebuilding a page', (
      tester,
    ) async {
      final content = StoryContentDbModel.create(createdAt: DateTime(2026)).withPages([
        StoryPageDbModel.markdown(id: 1, markdown: '### Trip\n\nHello'),
      ]);
      final pagesMap = StoryPageObjectsMap()..add(richPage: content.richPages!.single, readOnly: true);
      final pageController = PageController();
      addTearDown(() {
        pagesMap.dispose();
        pageController.dispose();
      });

      // One builder instance, as a story screen that isn't rebuilt by the keyboard passes it.
      final pages = StoryPagesBuilder(
        preferences: StoryPreferencesDbModel.create().copyWith(layoutType: layoutType),
        pages: [pagesMap[1]!],
        storyContent: content,
        headerBuilder: null,
        padding: EdgeInsets.zero,
        pageScrollController: ScrollController(),
        pageController: pageController,
      );

      Widget withKeyboard(double keyboard) {
        // The home indicator's 34 is covered by the keyboard as it rises.
        final bottomPadding = (34 - keyboard).clamp(0.0, 34.0);
        return MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(400, 800),
              viewPadding: const EdgeInsets.only(bottom: 34),
              padding: EdgeInsets.only(bottom: bottomPadding),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: Scaffold(body: pages),
          ),
        );
      }

      await tester.pumpWidget(withKeyboard(0));
      await tester.pumpAndSettle();
      final editor = tester.widget(find.byType(SpEditor));
      final bottomSpace = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_BottomSafeArea');
      expect(tester.getSize(bottomSpace).height, 34);

      for (final keyboard in [10.0, 20.0, 34.0, 120.0, 300.0]) {
        await tester.pumpWidget(withKeyboard(keyboard));
        expect(identical(tester.widget(find.byType(SpEditor)), editor), isTrue, reason: 'keyboard at $keyboard');
      }
      expect(tester.getSize(bottomSpace).height, 0, reason: 'the keyboard covers the home indicator');
    });
  }

  testWidgets('opening a page and typing never writes it out as Markdown; reading the page does, once', (tester) async {
    final content = StoryContentDbModel.create(createdAt: DateTime(2026)).withPages([
      StoryPageDbModel.markdown(id: 1, markdown: '### Trip\n\nHello'),
    ]);
    final pagesMap = StoryPageObjectsMap()..add(richPage: content.richPages!.single, readOnly: false);
    final pageController = PageController();
    addTearDown(() {
      pagesMap.dispose();
      pageController.dispose();
    });
    final page = pagesMap[1]!;
    var changes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryPagesBuilder(
            preferences: StoryPreferencesDbModel.create(),
            pages: [page],
            storyContent: content,
            headerBuilder: null,
            padding: EdgeInsets.zero,
            pageScrollController: ScrollController(),
            pageController: pageController,
            onPageChanged: () => changes++,
            actions: StoryPageBuilderAction(
              onAddPage: () {},
              onSwapPages: (_, _) {},
              onDelete: (_) {},
              canDeletePage: false,
            ),
          ),
        ),
      ),
    );
    page.bodyFocusNode.requestFocus();
    await tester.pumpAndSettle();

    final editor = page.bodyController.editor;
    for (final character in [' ', 'y', 'o', 'u']) {
      editor.editor.execute([InsertCharacterAtCaretRequest(character: character)]);
      await tester.pump();
    }
    expect(changes, 4, reason: 'every edit is reported');
    expect(editor.debugMarkdownWrites, 0, reason: 'not per keystroke');

    expect(page.page.markdown, '### Trip\n\nHello you');
    expect(editor.debugMarkdownWrites, 1);
  });
}
