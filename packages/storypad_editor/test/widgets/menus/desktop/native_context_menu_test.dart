import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../../../support/controller_helpers.dart';

/// On macOS the default right-click menu is a native NSMenu (the package's macos/ side), over a method channel.
void main() {
  const channel = MethodChannel('storypad_editor/context_menu');

  /// Answers the channel with [choice], recording each call.
  List<MethodCall> mockNativeMenu(WidgetTester tester, String? choice) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return choice;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    return calls;
  }

  Future<void> rightClick(WidgetTester tester) async {
    // On the text (the component spans the editor's width; past the text is outside the selection).
    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(8, 8), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
  }

  List<Map<Object?, Object?>> itemsOf(MethodCall call) => [
    for (final item in (call.arguments as Map)['items'] as List) item as Map<Object?, Object?>,
  ];

  testWidgets('editing: Cut, Copy, Paste, Select All, the extra items, Services -- and the choice runs', (
    tester,
  ) async {
    final calls = mockNativeMenu(tester, 'cut');
    final controller = controllerFor('Hello world');
    await StoryEditorTester.pump(
      tester,
      controller,
      editor: RawEditor(
        controller: controller,
        contextMenuActions: [StoryContextMenuAction(label: 'Uppercase', onPressed: () {})],
      ),
    );
    selectText(controller, 0, 0, 0, 11);
    await tester.pump();

    await rightClick(tester);

    final items = itemsOf(calls.single);
    expect(
      [for (final item in items) item['id'] ?? (item['divider'] == true ? '-' : 'services')],
      ['cut', 'copy', 'paste', '-', 'selectAll', '-', 'extra:0', '-', 'services'],
    );
    expect(items.firstWhere((item) => item['id'] == 'extra:0')['title'], 'Uppercase');
    expect(items.firstWhere((item) => item['id'] == 'paste')['enabled'], isTrue);
    expect(items.firstWhere((item) => item['id'] == 'cut')['enabled'], isTrue);
    expect((calls.single.arguments as Map)['selectedText'], 'Hello world', reason: 'for the Services submenu');
    expect(controller.toMarkdown(), '', reason: 'Cut ran');
    expect(find.text('Copy'), findsNothing, reason: 'no Flutter-painted menu');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('read-only: Cut and Paste disabled; an extra item runs its action', (tester) async {
    final calls = mockNativeMenu(tester, 'extra:0');
    var edits = 0;
    final controller = controllerFor('Hello world', readOnly: true);
    await StoryEditorTester.pump(
      tester,
      controller,
      editor: RawEditor(
        controller: controller,
        contextMenuActions: [
          StoryContextMenuAction(
            label: 'Edit',
            onPressed: () => edits++,
            whenEditing: false,
            whenReadOnly: true,
            needsSelection: false,
          ),
        ],
      ),
    );

    await rightClick(tester);

    final items = itemsOf(calls.single);
    expect(items.firstWhere((item) => item['id'] == 'cut')['enabled'], isFalse);
    expect(items.firstWhere((item) => item['id'] == 'paste')['enabled'], isFalse);
    expect(edits, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('without the native side: the Flutter-painted menu', (tester) async {
    // What a host without the package's macOS side answers.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) => throw MissingPluginException());
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final controller = controllerFor('Hello world');
    await StoryEditorTester.pump(tester, controller);

    await rightClick(tester);
    expect(find.text('Copy'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
