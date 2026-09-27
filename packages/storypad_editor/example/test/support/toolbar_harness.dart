import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:storypad_editor_example/embeds/demo_embeds.dart';
import 'package:storypad_editor_example/toolbar/editor_toolbar.dart';

/// Pumps a RawEditor with the example toolbar over [markdown], with some space above to tap "outside".
Future<StoryEditorController> pumpEditorWithToolbar(WidgetTester tester, String markdown) async {
  final controller = StoryEditorController(embeds: demoEmbeds, markdown: markdown);
  addTearDown(controller.dispose);
  await pumpStoryEditor(
    tester,
    controller,
    size: const Size(2400, 1200),
    editor: Column(
      children: [
        const SizedBox(height: 200, child: Center(child: Text('Outside area'))),
        Expanded(
          child: EditorWithToolbar(
            controller: controller,
            editor: RawEditor(controller: controller),
          ),
        ),
      ],
    ),
  );
  return controller;
}

/// Focuses the editor by tapping its text (touch platforms need this before the toolbar shows).
Future<void> focusEditor(WidgetTester tester) async {
  await tester.tap(find.byType(TextComponent).first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Selects [start, end) of the first block.
Future<void> selectInFirstBlock(WidgetTester tester, StoryEditorController controller, int start, int end) async {
  final id = controller.document.first.id;
  controller.composer.setSelectionWithReason(
    DocumentSelection(
      base: DocumentPosition(
        nodeId: id,
        nodePosition: TextNodePosition(offset: start),
      ),
      extent: DocumentPosition(
        nodeId: id,
        nodePosition: TextNodePosition(offset: end),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
