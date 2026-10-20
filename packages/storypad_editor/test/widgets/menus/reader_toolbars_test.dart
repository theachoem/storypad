import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../../support/controller_helpers.dart';

/// The selection menus while read-only: super_editor's reader shows none on Android and a bare "Copy" bubble on iOS.
void main() {
  late List<String> log;
  late String? clipboard;

  setUp(() {
    log = [];
    clipboard = null;
  });

  Future<StoryEditorController> pumpReader(
    WidgetTester tester, {
    int moreActions = 0,
    String markdown = 'Hello world',
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    final controller = controllerFor(markdown, readOnly: true);
    await StoryEditorTester.pump(
      tester,
      controller,
      editor: RawEditor(
        controller: controller,
        contextMenuActions: [
          StoryContextMenuAction(
            label: 'Edit',
            onPressed: () => log.add('edit'),
            whenEditing: false,
            whenReadOnly: true,
            needsSelection: false,
          ),
          for (var i = 1; i <= moreActions; i++)
            StoryContextMenuAction(label: 'Action $i', onPressed: () => log.add('action $i'), whenReadOnly: true),
        ],
      ),
    );

    // Long-press a word (in the last paragraph): selects it and shows the menu.
    await tester.longPressAt(tester.getTopLeft(find.byType(TextComponent).last) + const Offset(12, 8));
    await tester.pumpAndSettle();
    expect(controller.selection.value?.isCollapsed, isFalse, reason: 'the word is selected');
    return controller;
  }

  testWidgets('Android: Copy, Select all and the extra items show, and run', (tester) async {
    await pumpReader(tester);

    expect(find.text('Copy'), findsOneWidget);
    // The rest past the platform's narrow width, in the overflow menu.
    Future<bool> shown(String label) async {
      if (find.text(label).evaluate().isNotEmpty) return true;
      if (find.byIcon(Icons.more_vert).evaluate().isEmpty) return false;
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      return find.text(label).evaluate().isNotEmpty;
    }

    expect(await shown('Select all'), isTrue);
    expect(await shown('Edit'), isTrue);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(log, ['edit']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Android: a long ⋮ menu is capped, as native, and scrolls to its last item', (tester) async {
    await pumpReader(tester, moreActions: 10);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    final menu = find.ancestor(of: find.text('Action 1'), matching: find.byType(SingleChildScrollView));
    expect(tester.getSize(menu).height, 48 * 4.5);
    expect(tester.getSize(menu).width, greaterThan(tester.getSize(find.text('Action 10')).width));
    expect(find.byIcon(Icons.arrow_back), findsOneWidget, reason: 'the back button stays put, outside the list');

    await tester.dragUntilVisible(find.text('Action 10'), menu, const Offset(0, -48));
    await tester.tap(find.text('Action 10'));
    await tester.pumpAndSettle();
    expect(log, ['action 10']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Android: opening ⋮ morphs the toolbar as native Android does', (tester) async {
    await pumpReader(tester, moreActions: 10);
    final toolbar = tester.renderObject<RenderBox>(
      find.ancestor(
        of: find.byIcon(Icons.more_vert),
        matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_OverflowMorph'),
      ),
    );
    final closed = toolbar.size;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = toolbar.size;
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back), warnIfMissed: false);
    await tester.pumpAndSettle();
    final open = toolbar.size;
    expect(find.byIcon(Icons.more_vert), findsNothing, reason: 'nothing takes a tap while it morphs');

    // LocalFloatingToolbarPopup.openOverflow: 250ms (200 under a 150dp morph, 300 over 300), the width on
    // LogAccelerate and the height on FastOutSlowIn.
    final distance = Offset(closed.width - open.width, open.height - closed.height).distance;
    final milliseconds = distance < 150 ? 200 : (distance > 300 ? 300 : 250);
    final t = 100 / milliseconds;
    double logAccelerate(double t) {
      double log(double t) => 1 - math.pow(100, -t).toDouble();
      return 1 - log(1 - t) / log(1);
    }

    expect(
      midway.height,
      moreOrLessEquals(
        closed.height + (open.height - closed.height) * Curves.fastOutSlowIn.transform(t),
        epsilon: 0.01,
      ),
    );
    expect(
      midway.width,
      moreOrLessEquals(closed.width + (open.width - closed.width) * logAccelerate(t), epsilon: 0.01),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Android: ← closes the ⋮ menu back to the toolbar', (tester) async {
    await pumpReader(tester, moreActions: 10);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsNothing, reason: 'the closed toolbar is hidden while open');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Action 10'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(clipboard, isNotNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  group('Android: a toolbar with a ⋮ menu takes the open menu\'s room from the start', () {
    Finder byTypeName(String name) => find.byWidgetPredicate((widget) => widget.runtimeType.toString() == name);
    final toolbar = byTypeName('_OverflowMorph');
    final room = byTypeName('_TextSelectionToolbarTrailingEdgeAlign');

    testWidgets('without that room above the selection: below it right away, opening downwards in place', (
      tester,
    ) async {
      // Room above for the toolbar, not for its open menu.
      await pumpReader(tester, moreActions: 10, markdown: 'One\n\nTwo\n\nThree\n\nHello world');
      final selected = tester.getRect(find.byType(TextComponent).last);
      final closed = tester.getRect(toolbar);
      expect(closed.top, greaterThan(selected.bottom), reason: 'below the selection');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      final open = tester.getRect(toolbar);
      expect(open.top, closed.top, reason: 'the toolbar stayed put, the menu opening downwards');
      expect(open.height, greaterThan(closed.height));
      expect(tester.getCenter(find.byIcon(Icons.arrow_back)).dy, lessThan(tester.getCenter(find.text('Action 1')).dy));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('with it: above the selection, opening upwards in place', (tester) async {
      await pumpReader(
        tester,
        moreActions: 10,
        markdown: [for (var i = 1; i <= 20; i++) 'Line $i', 'Hello world'].join('\n\n'),
      );
      final selected = tester.getRect(find.byType(TextComponent).last);
      final closed = tester.getRect(toolbar);
      expect(closed.bottom, lessThan(selected.top), reason: 'above the selection');
      expect(tester.getRect(room).bottom, closed.bottom, reason: 'the room is above the toolbar');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      final open = tester.getRect(toolbar);
      expect(open.bottom, closed.bottom, reason: 'the toolbar stayed put, the menu opening upwards');
      expect(open.top, moreOrLessEquals(tester.getRect(room).top));
      expect(
        tester.getCenter(find.byIcon(Icons.arrow_back)).dy,
        greaterThan(tester.getCenter(find.text('Action 1')).dy),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('with room above for a shorter menu only: above, the menu shrunk to it (as native)', (tester) async {
      // The 11th paragraph: room above for three items, not four.
      await pumpReader(
        tester,
        moreActions: 10,
        markdown: [for (var i = 1; i <= 10; i++) 'Line $i', 'Hello world'].join('\n\n'),
      );
      final closed = tester.getRect(toolbar);
      expect(closed.bottom, lessThan(tester.getRect(find.byType(TextComponent).last).top), reason: 'above');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      final list = find.ancestor(of: find.text('Action 1'), matching: find.byType(SingleChildScrollView));
      expect(tester.getSize(list).height, 48 * 3.5, reason: 'three items and half of a fourth');
      expect(tester.getRect(toolbar).bottom, closed.bottom, reason: 'opening upwards in place');
      expect(tester.getRect(toolbar).top, greaterThanOrEqualTo(0), reason: 'on screen');
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('the room the closed toolbar leaves takes no taps', (tester) async {
      await pumpReader(
        tester,
        moreActions: 10,
        markdown: [for (var i = 1; i <= 20; i++) 'Line $i', 'Hello world'].join('\n\n'),
      );
      final closed = tester.getRect(toolbar);
      expect(tester.getRect(room).top, lessThan(closed.top - 48));

      // Whether a tap at [position] reaches the room's box.
      bool hitsRoom(Offset position) {
        final target = tester.renderObject(room);
        return tester.hitTestOnBinding(position).path.any((entry) => entry.target == target);
      }

      expect(hitsRoom(closed.center), isTrue, reason: 'the toolbar itself does');
      // Over the text, in the room above the toolbar: the reader gets it.
      expect(hitsRoom(Offset(closed.center.dx, closed.top - 24)), isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  testWidgets('Android: Copy copies, and the selection and toolbar go', (tester) async {
    final controller = await pumpReader(tester);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(clipboard, 'Hello');
    expect(controller.selection.value, isNull, reason: 'copied, the selection and toolbar go');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('iOS: the iOS-style menu, with Copy, Select All and the extra items', (tester) async {
    final controller = await pumpReader(tester);

    expect(find.byType(CupertinoTextSelectionToolbar), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();
    final selection = controller.selection.value!;
    expect(controller.document.getNodeById(selection.end.nodeId), controller.document.last);
    expect((selection.end.nodePosition as TextNodePosition).offset, 'Hello world'.length);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(log, ['edit']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
