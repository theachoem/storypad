import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../../support/controller_helpers.dart';

void main() {
  testWidgets('read-only shows a reader (no typing), and switching back restores the editor', (tester) async {
    final controller = controllerFor('Hello', readOnly: true);
    await StoryEditorTester.pump(tester, controller);

    expect(find.byType(SuperReader), findsOneWidget);
    expect(find.byType(SuperEditor), findsNothing);

    controller.readOnly = false;
    await tester.pumpAndSettle();
    expect(find.byType(SuperEditor), findsOneWidget);
    expect(find.byType(SuperReader), findsNothing);
  });

  testWidgets('task checkboxes still toggle, as a reported edit', (tester) async {
    final controller = controllerFor('- [ ] Water the plants', readOnly: true);
    final reported = <String>[];
    await StoryEditorTester.pump(
      tester,
      controller,
      editor: MarkdownEditor(controller: controller, onChanged: reported.add, debounce: Duration.zero),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(controller.toMarkdown(), '- [x] Water the plants');
    expect(reported, ['- [x] Water the plants']);
  });

  testWidgets('embeds render in read-only, told so', (tester) async {
    final controller = controllerFor('<sp-sticker name="cat"></sp-sticker>', readOnly: true);
    await StoryEditorTester.pump(tester, controller);

    expect(find.text('sticker cat (read-only)'), findsOneWidget);
  });

  testWidgets('the scroll position is kept when switching to read-only and back', (tester) async {
    final controller = controllerFor([for (var i = 0; i < 200; i++) 'Line $i'].join('\n\n'));
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await StoryEditorTester.pump(
      tester,
      controller,
      size: const Size(800, 600),
      editor: RawEditor(controller: controller, scrollController: scrollController),
    );

    scrollController.jumpTo(1500);
    await tester.pumpAndSettle();

    controller.readOnly = true;
    await tester.pumpAndSettle();
    expect(scrollController.offset, 1500);

    controller.readOnly = false;
    await tester.pumpAndSettle();
    expect(scrollController.offset, 1500);
  });

  testWidgets('the scroll position is kept without an app-provided scroll controller too', (tester) async {
    final controller = controllerFor([for (var i = 0; i < 200; i++) 'Line $i'].join('\n\n'));
    await StoryEditorTester.pump(tester, controller, size: const Size(800, 600));

    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -1200));
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(before, greaterThan(0));

    controller.readOnly = true;
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, before);
  });
}
