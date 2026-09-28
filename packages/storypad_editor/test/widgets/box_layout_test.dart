import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';
import '../support/test_embeds.dart';

/// The box layout: an editor sized to its content in a `Column` inside someone else's scroll view (e.g. below a title
/// field), which scrolls it.
void main() {
  final longStory = List.generate(40, (i) => 'Paragraph number $i').join('\n\n');

  Future<ScrollController> pumpInScrollView(WidgetTester tester, StoryEditorController controller) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await pumpStoryEditor(
      tester,
      controller,
      size: const Size(400, 600),
      editor: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: 80, child: Center(child: Text('Title'))),
            RawEditor(controller: controller, layout: StoryEditorLayout.box),
            const SizedBox(height: 48, child: Center(child: Text('Below'))),
          ],
        ),
      ),
    );
    return scrollController;
  }

  for (final readOnly in [false, true]) {
    testWidgets('sizes to its content between other widgets${readOnly ? ' (read-only)' : ''}', (tester) async {
      final controller = controllerFor('One\n\nTwo', readOnly: readOnly);
      await pumpInScrollView(tester, controller);

      final title = tester.getRect(find.text('Title'));
      final below = tester.getRect(find.text('Below'));
      final one = tester.getRect(find.byType(TextComponent).first);
      expect(one.top, greaterThan(title.bottom));
      expect(below.top, greaterThan(tester.getRect(find.byType(TextComponent).last).bottom));
      // Much shorter than the 600px screen: it isn't filling the space.
      expect(below.top, lessThan(400));
    });
  }

  testWidgets('grows as content is added', (tester) async {
    final controller = controllerFor('One');
    await pumpInScrollView(tester, controller);
    final before = tester.getTopLeft(find.text('Below')).dy;

    placeCaret(controller, 0, 3);
    await tester.pump();
    controller.insertEmbed(const StickerEmbedCodec(), 'cat');
    controller.insertEmbed(const StickerEmbedCodec(), 'dog');
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Below')).dy, greaterThan(before + 20));
  });

  for (final readOnly in [false, true]) {
    testWidgets('dragging over the text scrolls the scroll view around it${readOnly ? ' (read-only)' : ''}', (
      tester,
    ) async {
      final controller = controllerFor(longStory, readOnly: readOnly);
      final scrollController = await pumpInScrollView(tester, controller);
      expect(scrollController.offset, 0);

      await tester.dragFrom(const Offset(200, 400), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(100));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  testWidgets('the scroll view follows the caret', (tester) async {
    final controller = controllerFor(longStory);
    final scrollController = await pumpInScrollView(tester, controller);

    controller.focusNode.requestFocus();
    await tester.pumpAndSettle();
    placeCaret(controller, 39, 0);
    await tester.pumpAndSettle();
    // Typing: iOS brings the caret into view on edits (in any layout), Android on selection changes too.
    controller.editor.execute([
      InsertTextRequest(documentPosition: controller.selection.value!.extent, textToInsert: 'x', attributions: {}),
    ]);
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(0));
    final last = tester.widgetList<TextComponent>(find.byType(TextComponent)).last;
    final rect = tester.getRect(find.byWidget(last));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(600));
  }, variant: TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

  testWidgets('a tap places the caret in the tapped block', (tester) async {
    final controller = controllerFor('One\n\nTwo\n\nThree');
    await pumpInScrollView(tester, controller);

    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent).at(1)) + const Offset(4, 8));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(controller.selection.value?.extent.nodeId, nodeAt(controller, 1).id);
  }, variant: TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}));

  testWidgets('without a scroll view around it, it still sizes to its content', (tester) async {
    final controller = controllerFor('One');
    await pumpStoryEditor(
      tester,
      controller,
      size: const Size(400, 600),
      editor: Column(
        children: [
          RawEditor(controller: controller, layout: StoryEditorLayout.box),
          const Text('Below'),
        ],
      ),
    );
    expect(tester.getTopLeft(find.text('Below')).dy, lessThan(200));
  });
}
