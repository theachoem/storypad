import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        IOSSystemContextMenuItemDataCut,
        IOSSystemContextMenuItemDataCopy,
        IOSSystemContextMenuItemDataPaste,
        IOSSystemContextMenuItemDataSelectAll,
        IOSSystemContextMenuItemDataLookUp,
        IOSSystemContextMenuItemDataSearchWeb,
        IOSSystemContextMenuItemDataShare,
        IOSSystemContextMenuItemDataCustom;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/src/widgets/ios_system_context_menu.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// The app's extra items in the editor's selection menus.
void main() {
  List<StoryContextMenuAction> actionsFor(StoryEditorController controller, List<String> log) => [
    StoryContextMenuAction(
      label: 'Upper',
      onPressed: () => controller.actions.transformSelectedText((text) => text.toUpperCase()),
    ),
    StoryContextMenuAction(
      label: 'Open editor',
      onPressed: () => log.add('edit'),
      whenEditing: false,
      whenReadOnly: true,
      needsSelection: false,
    ),
  ];

  // The Flutter-painted menu (Windows/Linux); macOS's native one: native_context_menu_test.
  group('desktop right-click menu', () {
    testWidgets('offers the editing items for a selection, and runs the chosen one', (tester) async {
      final controller = controllerFor('Hello world');
      final log = <String>[];
      await pumpStoryEditor(
        tester,
        controller,
        editor: RawEditor(controller: controller, contextMenuActions: actionsFor(controller, log)),
      );
      selectNode(controller, 0);
      await tester.pump();

      await tester.tapAt(
        tester.getTopLeft(find.byType(TextComponent)) + const Offset(12, 8),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();

      expect(find.text('Upper'), findsOneWidget);
      expect(find.text('Open editor'), findsNothing);
      await tester.tap(find.text('Upper'));
      await tester.pumpAndSettle();
      expect(controller.toMarkdown(), 'HELLO WORLD');
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('read-only: offers the read-only items', (tester) async {
      final controller = controllerFor('Hello world', readOnly: true);
      final log = <String>[];
      await pumpStoryEditor(
        tester,
        controller,
        editor: RawEditor(controller: controller, contextMenuActions: actionsFor(controller, log)),
      );

      await tester.tapAt(
        tester.getTopLeft(find.byType(TextComponent)) + const Offset(12, 8),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();

      expect(find.text('Upper'), findsNothing);
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      expect(log, ['edit']);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  testWidgets('Android toolbar: the items follow the platform\'s', (tester) async {
    final controller = controllerFor('Hello world');
    await pumpStoryEditor(
      tester,
      controller,
      editor: RawEditor(controller: controller, contextMenuActions: actionsFor(controller, [])),
    );

    // Focus the editor (unfocused, a long-press reorders blocks), then long-press a word: selects it and shows the
    // toolbar.
    final word = tester.getTopLeft(find.byType(TextComponent)) + const Offset(12, 8);
    await tester.tapAt(word);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.longPressAt(word);
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    // Past the platform's items, in the overflow menu (the toolbar is as narrow as Android's own).
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Upper'), findsOneWidget);
    await tester.tap(find.text('Upper'));
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), 'HELLO world');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  test('iOS system menu items: the standard ones for the selection, then the shown extras', () {
    final actions = actionsFor(controllerFor(''), []);
    const localizations = DefaultWidgetsLocalizations();

    final withSelection = StoryIosSystemContextMenu.itemsFor(
      localizations: localizations,
      hasSelection: true,
      extraActions: actions,
    );
    expect(withSelection.map((item) => item.runtimeType), [
      IOSSystemContextMenuItemDataCut,
      IOSSystemContextMenuItemDataCopy,
      IOSSystemContextMenuItemDataPaste,
      IOSSystemContextMenuItemDataSelectAll,
      IOSSystemContextMenuItemDataLookUp,
      IOSSystemContextMenuItemDataSearchWeb,
      IOSSystemContextMenuItemDataShare,
      IOSSystemContextMenuItemDataCustom,
    ]);
    expect(withSelection.last.title, 'Upper');

    final caretOnly = StoryIosSystemContextMenu.itemsFor(
      localizations: localizations,
      hasSelection: false,
      extraActions: actions,
    );
    expect(caretOnly.map((item) => item.runtimeType), [
      IOSSystemContextMenuItemDataPaste,
      IOSSystemContextMenuItemDataSelectAll,
    ]);
  });
}
