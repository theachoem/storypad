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
}
