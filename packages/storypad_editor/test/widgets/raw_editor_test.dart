import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

Future<void> _pumpWithOutside(WidgetTester tester, StoryEditorController controller, {Widget? toolbar}) {
  return pumpStoryEditor(
    tester,
    controller,
    editor: Column(
      children: [
        const SizedBox(height: 300, child: Center(child: Text('Outside area'))),
        Expanded(child: RawEditor(controller: controller)),
        ?toolbar,
      ],
    ),
  );
}

void main() {
  testWidgets('on touch, tapping outside the editor leaves it focused (the keyboard hides it)', (tester) async {
    final controller = controllerFor('Hello world');
    await _pumpWithOutside(tester, controller);

    await tester.tap(find.byType(TextComponent), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(controller.selection.value, isNotNull);

    await tester.tap(find.text('Outside area'));
    await tester.pumpAndSettle();
    expect(controller.focusNode.hasFocus, isTrue);
    expect(controller.selection.value, isNotNull);
    expect(controller.isToolbarActive.value, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('tapping a toolbar in the controller\'s tap region group does not unfocus the editor', (tester) async {
    final controller = controllerFor('Hello world');
    await _pumpWithOutside(
      tester,
      controller,
      toolbar: TapRegion(
        groupId: controller.tapRegionGroupId,
        child: TextButton(onPressed: () {}, child: const Text('Toolbar button')),
      ),
    );

    await tester.tap(find.byType(TextComponent), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toolbar button'));
    await tester.pumpAndSettle();

    expect(controller.selection.value, isNotNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a selection hold keeps the selection while focus is elsewhere (e.g. a toolbar dialog)', (tester) async {
    final controller = controllerFor('Hello world');
    final elsewhere = FocusNode();
    addTearDown(elsewhere.dispose);
    await _pumpWithOutside(
      tester,
      controller,
      toolbar: Focus(focusNode: elsewhere, child: const SizedBox()),
    );

    await tester.tap(find.byType(TextComponent), warnIfMissed: false);
    await tester.pumpAndSettle();
    selectText(controller, 0, 0, 0, 5);
    await tester.pump();

    final hold = controller.holdSelection();
    await tester.pump();
    elsewhere.requestFocus();
    await tester.pumpAndSettle();
    expect(controller.selection.value, isNotNull, reason: 'held');
    expect(controller.isToolbarActive.value, isTrue, reason: 'held, though unfocused');

    hold.release();
    await tester.pump();
    expect(controller.isToolbarActive.value, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('desktop: right-click shows the context menu; a custom handler replaces it', (tester) async {
    final controller = controllerFor('Hello world');
    DesktopContextMenuRequest? request;
    await pumpStoryEditor(
      tester,
      controller,
      editor: RawEditor(
        controller: controller,
        desktopContextMenu: (r) async {
          request = r;
          return DesktopContextMenuAction.selectAll;
        },
      ),
    );

    await tester.tap(find.byType(TextComponent), buttons: kSecondaryButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(request, isNotNull);
    final selection = controller.selection.value!;
    expect(selection.isCollapsed, isFalse, reason: 'Select All ran');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('desktop: the default context menu', (tester) async {
    final controller = controllerFor('Hello world');
    await pumpStoryEditor(tester, controller);

    await tester.tap(find.byType(TextComponent), buttons: kSecondaryButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Select all'), findsOneWidget);
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(controller.selection.value!.isCollapsed, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('two editors sharing a controller are reported', (tester) async {
    final controller = controllerFor('a');
    final reported = <FlutterErrorDetails>[];
    final onError = FlutterError.onError;
    FlutterError.onError = reported.add;

    await pumpStoryEditor(
      tester,
      controller,
      editor: Column(
        children: [
          Expanded(child: RawEditor(controller: controller)),
          Expanded(child: RawEditor(controller: controller)),
        ],
      ),
    );
    FlutterError.onError = onError; // Restore before the test ends (the framework checks).

    expect(
      reported.map((details) => '${details.exception}'),
      contains(contains('Each editor needs its own controller')),
    );
  });

  testWidgets('parent rebuilds and focus changes reuse the stylesheet and builders (no presenter rebuild)', (
    tester,
  ) async {
    final controller = controllerFor('Hello');
    late StateSetter rebuildParent;
    await pumpStoryEditor(
      tester,
      controller,
      editor: StatefulBuilder(
        builder: (context, setState) {
          rebuildParent = setState;
          return RawEditor(controller: controller);
        },
      ),
    );
    SuperEditor superEditor() => tester.widget<SuperEditor>(find.byType(SuperEditor));
    final stylesheet = superEditor().stylesheet;
    final builders = superEditor().componentBuilders;

    rebuildParent(() {});
    await tester.pump();
    controller.focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(identical(superEditor().stylesheet, stylesheet), isTrue);
    expect(
      superEditor().componentBuilders.take(builders.length - 1).toList(),
      orderedEquals(builders.take(builders.length - 1)),
      reason: 'same builder objects (SuperEditor appends its own unknown builder)',
    );
  });
}
