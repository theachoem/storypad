import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_adapter.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_controller.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad_editor/super_editor.dart';

/// A page and its toolbar, as the story page hosts them, in the page's scroll view.
void main() {
  final adapter = StoryPadEditorRichTextAdapter();

  Future<({StoryPadEditorRichTextController controller, FocusNode focusNode, List<int> changes})> pumpPage(
    WidgetTester tester, {
    String markdown = '',
    bool readOnly = false,
    bool keepsChanges = true,
    VoidCallback? onGoToEdit,
  }) async {
    final controller =
        adapter.createController(
              markdown: markdown,
              selection: const TextSelection.collapsed(offset: 0),
              readOnly: readOnly,
            )
            as StoryPadEditorRichTextController;
    final focusNode = FocusNode();
    final changes = <int>[];
    addTearDown(() {
      focusNode.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: Column(
                children: [
                  adapter.buildEditor(
                    context: context,
                    controller: controller,
                    focusNode: focusNode,
                    scrollController: ScrollController(),
                    readOnly: readOnly,
                    storyContent: StoryContentDbModel.create(),
                    onChanged: keepsChanges ? () => changes.add(changes.length) : null,
                    onGoToEdit: onGoToEdit,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Builder(
            builder: (context) => adapter.buildToolbar(context: context, controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (controller: controller, focusNode: focusNode, changes: changes);
  }

  testWidgets('focusing the page focuses the editor, with the caret at the end', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );

    page.focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(page.controller.editor.focusNode.hasFocus, isTrue);
    expect(page.focusNode.hasFocus, isTrue, reason: 'the page and its toolbar track this node');
    expect(page.controller.selection, const TextSelection.collapsed(offset: 5));
  });

  testWidgets('edits are reported right away (so Done never misses the last keystrokes)', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );
    page.focusNode.requestFocus();
    await tester.pumpAndSettle();

    page.controller.editor.editor.execute([
      InsertTextRequest(
        documentPosition: page.controller.editor.selection.value!.extent,
        textToInsert: ' world',
        attributions: {},
      ),
    ]);
    // Reported in a microtask right after the edit, before any later tap (e.g. Done) is handled.
    await Future<void>.value();

    expect(page.changes, isNotEmpty);
    expect(page.controller.serialize(), 'Hello world');
  });

  testWidgets('the toolbar formats the selection', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );
    page.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.tap(find.byIcon(SpIcons.formatBold));
    await tester.pumpAndSettle();

    expect(page.controller.serialize(), '**Hello**');
  });

  testWidgets('a view whose changes aren\'t kept has no live checkboxes', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: '- [ ] task',
      readOnly: true,
      keepsChanges: false,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(page.controller.editor.toMarkdown(), '- [ ] task');
  });

  testWidgets('read-only with changes kept: a checkbox toggle is reported', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: '- [ ] task',
      readOnly: true,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(page.changes, isNotEmpty);
    expect(page.controller.serialize(), '- [x] task');
  });

  testWidgets('read-only, the right-click menu offers Edit; editing, Uppercase and Lowercase', (tester) async {
    var edits = 0;
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
      readOnly: true,
      onGoToEdit: () => edits++,
    );

    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(8, 8), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Uppercase'), findsNothing);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(page.controller.readOnly, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('editing: Uppercase changes the selected text', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'Hello',
    );
    page.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(8, 8), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uppercase'));
    await tester.pumpAndSettle();
    expect(page.controller.serialize(), 'HELLO');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('content changed before the page is built is reported once it is (a story started from a photo)', (
    tester,
  ) async {
    final controller =
        adapter.createController(markdown: '', selection: const TextSelection.collapsed(offset: 0), readOnly: false)
            as StoryPadEditorRichTextController;
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      controller.dispose();
    });
    // As EditStoryViewModel.init does for an initial asset (a photo; text here, since rendering a photo needs the app's
    // providers), before the page is built.
    controller.replaceText(0, 0, 'Hello', null);

    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: adapter.buildEditor(
                context: context,
                controller: controller,
                focusNode: focusNode,
                scrollController: ScrollController(),
                readOnly: false,
                storyContent: StoryContentDbModel.create(),
                onChanged: () => changes.add(changes.length),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(changes, hasLength(1));
    expect(controller.serialize(), 'Hello');
  });

  testWidgets('with text selected, undo/redo become move up/down and move the selected lines', (tester) async {
    final page = await pumpPage(
      tester,
      markdown: 'one\n\ntwo\n\nthree',
    );
    expect(find.byIcon(SpIcons.undo), findsOneWidget);

    // Select "two" (offsets: "one\n" is 4).
    page.controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
    await tester.pump();
    expect(find.byIcon(SpIcons.undo), findsNothing);

    await tester.tap(find.byIcon(SpIcons.moveUp));
    await tester.pumpAndSettle();
    expect(page.controller.serialize(), 'two\n\none\n\nthree');
  });

  group('the page title (its leading heading)', () {
    Future<StoryPadEditorRichTextController> pumpTitled(
      WidgetTester tester, {
      required String markdown,
      bool readOnly = false,
      TextStyle? titleStyle,
    }) async {
      final controller =
          adapter.createController(
                markdown: markdown,
                selection: const TextSelection.collapsed(offset: 0),
                readOnly: readOnly,
              )
              as StoryPadEditorRichTextController;
      final focusNode = FocusNode();
      addTearDown(() {
        focusNode.dispose();
        controller.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                child: adapter.buildEditor(
                  context: context,
                  controller: controller,
                  focusNode: focusNode,
                  scrollController: ScrollController(),
                  readOnly: readOnly,
                  storyContent: StoryContentDbModel.create(),
                  onChanged: () {},
                  titleStyle: titleStyle,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('an empty title shows the title hint while editing, not while reading', (tester) async {
      await pumpTitled(tester, markdown: '###\n\nbody');
      expect(find.text('Title...', findRichText: true), findsOneWidget);

      await pumpTitled(tester, markdown: '###\n\nbody', readOnly: true);
      expect(find.text('Title...', findRichText: true), findsNothing);
    });

    testWidgets('the title gets the title style; a heading further down keeps the heading style', (tester) async {
      await pumpTitled(
        tester,
        markdown: '### Trip\n\nbody\n\n### Later',
        titleStyle: const TextStyle(fontSize: 13, color: Color(0xFF00FF00)),
      );

      TextStyle styleOf(String text) {
        final root = tester.widget<RichText>(find.text(text, findRichText: true)).text;
        TextStyle? found;
        void visit(InlineSpan span, TextStyle inherited) {
          final style = inherited.merge(span.style);
          if (span is TextSpan && span.text == text) found = style;
          if (span is TextSpan) span.children?.forEach((child) => visit(child, style));
        }

        visit(root, const TextStyle());
        return found!;
      }

      expect(styleOf('Trip').fontSize, 13);
      expect(styleOf('Trip').color, const Color(0xFF00FF00));
      expect(styleOf('Later').fontSize, 24);
    });
  });
}
