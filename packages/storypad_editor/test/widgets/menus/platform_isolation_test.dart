import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/src/widgets/menus/desktop/desktop_context_menu_region.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../../support/controller_helpers.dart';

/// Each platform's menus stay on that platform: the iOS and Android selection toolbars are only reachable in their own
/// gesture mode, the right-click menu only wraps the editor on desktop, and only Android asks its side for Process Text
/// apps.
void main() {
  const desktop = {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux};
  const processTextChannel = MethodChannel('storypad_editor/process_text');

  DocumentGestureMode gestureModeFor(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS => DocumentGestureMode.iOS,
    TargetPlatform.android => DocumentGestureMode.android,
    _ => DocumentGestureMode.mouse,
  };

  testWidgets('the editor uses only its own platform\'s toolbar, menu and Process Text', (tester) async {
    final platform = defaultTargetPlatform;
    var processTextQueries = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(processTextChannel, (call) async {
      if (call.method == 'queryTextActions') processTextQueries++;
      return const <Object?>[];
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(processTextChannel, null));

    final controller = controllerFor('Hello world');
    await StoryEditorTester.pump(tester, controller);

    // The iOS and Android toolbar builders are only called in their own gesture mode.
    expect(tester.state<SuperEditorState>(find.byType(SuperEditor)).gestureMode, gestureModeFor(platform));
    expect(find.byType(DesktopContextMenuRegion), desktop.contains(platform) ? findsOneWidget : findsNothing);

    selectText(controller, 0, 0, 0, 5);
    await tester.pumpAndSettle();
    expect(processTextQueries, platform == TargetPlatform.android ? greaterThan(0) : 0);
  }, variant: TargetPlatformVariant.all());

  testWidgets('read-only, the right-click menu only wraps the reader on desktop', (tester) async {
    final controller = controllerFor('Hello world', readOnly: true);
    await StoryEditorTester.pump(tester, controller);

    expect(
      find.byType(DesktopContextMenuRegion),
      desktop.contains(defaultTargetPlatform) ? findsOneWidget : findsNothing,
    );
  }, variant: TargetPlatformVariant.all());
}
