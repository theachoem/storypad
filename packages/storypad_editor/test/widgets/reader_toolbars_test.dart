import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// The selection menus while read-only: super_editor's reader shows none on Android and a bare "Copy" bubble on iOS.
void main() {
  late List<String> log;
  late String? clipboard;

  setUp(() {
    log = [];
    clipboard = null;
  });

  Future<StoryEditorController> pumpReader(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    final controller = controllerFor('Hello world', readOnly: true);
    await pumpStoryEditor(
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
        ],
      ),
    );

    // Long-press a word: selects it and shows the menu.
    await tester.longPressAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(12, 8));
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
