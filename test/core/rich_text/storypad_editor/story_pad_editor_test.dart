import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_adapter.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_controller.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad_editor/super_editor.dart';

/// A page body and its toolbar, as the story page hosts them: a title above, in the page's scroll view.
void main() {
  final adapter = StoryPadEditorRichTextAdapter();

  Future<({StoryPadEditorRichTextController controller, FocusNode focusNode, List<int> changes})> pumpPage(
    WidgetTester tester, {
    List<dynamic> json = const [],
    bool readOnly = false,
    bool keepsChanges = true,
    VoidCallback? onGoToEdit,
  }) async {
    final controller =
        adapter.createController(
              json: json,
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
                  const TextField(decoration: InputDecoration(hintText: 'Title')),
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
      json: [
        {'insert': 'Hello\n'},
      ],
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
      json: [
        {'insert': 'Hello\n'},
      ],
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
    expect(page.controller.serialize(), [
      {'insert': 'Hello world\n'},
    ]);
  });

  testWidgets('the toolbar formats the selection', (tester) async {
    final page = await pumpPage(
      tester,
      json: [
        {'insert': 'Hello\n'},
      ],
    );
    page.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.tap(find.byIcon(SpIcons.formatBold));
    await tester.pumpAndSettle();

    expect(page.controller.serialize(), [
      {
        'insert': 'Hello',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ]);
  });

  testWidgets('a view whose changes aren\'t kept has no live checkboxes', (tester) async {
    final page = await pumpPage(
      tester,
      json: [
        {'insert': 'task'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ],
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
      json: [
        {'insert': 'task'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ],
      readOnly: true,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(page.changes, isNotEmpty);
    expect(page.controller.serialize(), [
      {'insert': 'task'},
      {
        'insert': '\n',
        'attributes': {'list': 'checked'},
      },
    ]);
  });

  testWidgets('read-only, the right-click menu offers Edit; editing, Uppercase and Lowercase', (tester) async {
    var edits = 0;
    final page = await pumpPage(
      tester,
      json: [
        {'insert': 'Hello\n'},
      ],
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
      json: [
        {'insert': 'Hello\n'},
      ],
    );
    page.controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(8, 8), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uppercase'));
    await tester.pumpAndSettle();
    expect(page.controller.serialize(), [
      {'insert': 'HELLO\n'},
    ]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('content changed before the page is built is reported once it is (a story started from a photo)', (
    tester,
  ) async {
    final controller =
        adapter.createController(json: const [], selection: const TextSelection.collapsed(offset: 0), readOnly: false)
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
    expect(controller.serialize(), [
      {'insert': 'Hello\n'},
    ]);
  });

  testWidgets('with text selected, undo/redo become move up/down and move the selected lines', (tester) async {
    final page = await pumpPage(
      tester,
      json: [
        {'insert': 'one\ntwo\nthree\n'},
      ],
    );
    expect(find.byIcon(SpIcons.undo), findsOneWidget);

    // Select "two" (offsets: "one\n" is 4).
    page.controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
    await tester.pump();
    expect(find.byIcon(SpIcons.undo), findsNothing);

    await tester.tap(find.byIcon(SpIcons.moveUp));
    await tester.pumpAndSettle();
    expect(page.controller.serialize(), [
      {'insert': 'two\none\nthree\n'},
    ]);
  });
}
