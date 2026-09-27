import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:storypad_editor_example/embeds/demo_embeds.dart';
import 'package:storypad_editor_example/native_context_menu.dart';

void main() {
  testWidgets('the native menu gets the items and selected text, and its choice runs', (tester) async {
    MethodCall? call;
    const channel = MethodChannel('storypad_editor_example/native_context_menu');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
      call = c;
      return 'selectAll';
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    final controller = StoryEditorController(embeds: demoEmbeds, markdown: 'Hello world');
    addTearDown(controller.dispose);
    await pumpStoryEditor(
      tester,
      controller,
      editor: RawEditor(controller: controller, desktopContextMenu: showDesktopContextMenu),
    );

    await tester.tap(find.byType(TextComponent), buttons: kSecondaryButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    final items = (call!.arguments as Map)['items'] as List;
    expect(items.map((item) => (item as Map)['id']).whereType<String>(), ['cut', 'copy', 'paste', 'selectAll']);
    expect(controller.selection.value!.isCollapsed, isFalse, reason: 'Select All ran');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
