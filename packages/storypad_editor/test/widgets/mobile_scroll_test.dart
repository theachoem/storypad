import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/testing.dart';

import '../support/controller_helpers.dart';

/// On touch, dragging on text scrolls the document (nothing sits on top of it).
void main() {
  testWidgets('the document scrolls by dragging on text while the editor is unfocused', (tester) async {
    final controller = controllerFor([for (var i = 0; i < 200; i++) 'Line $i'].join('\n\n'));
    await pumpStoryEditor(tester, controller, size: const Size(800, 600));
    expect(controller.focusNode.hasFocus, isFalse);

    await tester.drag(find.text('Line 3', findRichText: true), const Offset(0, -400));
    await tester.pumpAndSettle();

    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(position.pixels, greaterThan(0));
    expect(controller.focusNode.hasFocus, isFalse, reason: 'a drag is not a tap');
  }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
}
