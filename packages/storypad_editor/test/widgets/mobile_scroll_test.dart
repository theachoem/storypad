import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/testing.dart';

import '../support/controller_helpers.dart';

/// Regression: while unfocused on touch, the reorder overlay's per-block gesture regions sat on top of the document
/// opaquely, so dragging on text couldn't scroll it.
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

  testWidgets('after scrolling, long-pressing a block picks up that block (regions follow the scroll)', (tester) async {
    final controller = controllerFor([for (var i = 0; i < 200; i++) 'Line $i'].join('\n\n'));
    await pumpStoryEditor(tester, controller, size: const Size(800, 600));

    await tester.drag(find.text('Line 3', findRichText: true), const Offset(0, -500));
    await tester.pumpAndSettle();

    final target = find.text('Line 20', findRichText: true);
    final start = tester.getCenter(target);
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.touch);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(start + const Offset(0, 90));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final lines = controller.document.map((node) => (node as dynamic).text.toPlainText() as String).toList();
    expect(lines.indexOf('Line 20'), greaterThan(20), reason: 'Line 20 moved down');
    expect(lines.indexOf('Line 21'), 20, reason: 'its neighbor moved up');
  });
}
