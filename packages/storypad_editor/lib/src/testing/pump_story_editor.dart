import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../controller/story_editor_controller.dart';
import '../widgets/raw_editor.dart';

/// Pumps a [RawEditor] for [controller] in a minimal Material app (or [editor], e.g. a `MarkdownEditor`, when given),
/// and lets it settle -- including the extra frame the reorder overlays need to measure the document.
///
/// Dispose the controller with `addTearDown(controller.dispose)`: tear-down callbacks run after the test's widget
/// tree is unmounted, which is the order the controller requires.
///
/// For platform-specific behavior, use `testWidgets(..., variant: TargetPlatformVariant.only(TargetPlatform.iOS))`
/// rather than setting `debugDefaultTargetPlatformOverride` (which must be reset before tear-down runs).
Future<void> pumpStoryEditor(
  WidgetTester tester,
  StoryEditorController controller, {
  Widget? editor,
  Size size = const Size(800, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: editor ?? RawEditor(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
}
