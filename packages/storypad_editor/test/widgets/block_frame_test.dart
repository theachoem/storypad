import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Block frames: a decoration and inner padding per block type.
void main() {
  Container? frameAround(WidgetTester tester, String text) {
    final component = find.byWidgetPredicate(
      (widget) => widget is TextComponent && widget.text.toPlainText() == text,
    );
    return tester
        .widgetList<Container>(find.ancestor(of: component, matching: find.byType(Container)))
        .where((container) => container.decoration != null)
        .firstOrNull;
  }

  testWidgets('by default, quotes and code blocks are framed with their content inset; paragraphs are not', (
    tester,
  ) async {
    final controller = controllerFor('plain\n\n> quoted\n\n```\ncode\n```');
    await pumpStoryEditor(tester, controller);

    expect(frameAround(tester, 'plain'), isNull);
    expect(frameAround(tester, 'quoted')!.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
    expect(frameAround(tester, 'code')!.padding, const EdgeInsets.all(12));

    // The content is inset inside the frame.
    final frame = tester.getRect(find.byWidget(frameAround(tester, 'quoted')!));
    final text = tester.getRect(
      find.byWidgetPredicate((widget) => widget is TextComponent && widget.text.toPlainText() == 'quoted'),
    );
    expect(text.left - frame.left, 3 + 12, reason: "inside the 3px bar");
    expect(text.top - frame.top, 8);
  });

  testWidgets('an app\'s own frames replace the defaults; an empty map frames nothing', (tester) async {
    final controller = controllerFor('plain\n\n> quoted');
    const style = StoryBlockStyle(decoration: BoxDecoration(color: Color(0xFFFF0000)), padding: EdgeInsets.all(20));
    await pumpStoryEditor(
      tester,
      controller,
      editor: RawEditor(controller: controller, blockStyles: const {'paragraph': style}),
    );
    expect(frameAround(tester, 'plain')!.padding, const EdgeInsets.all(20));
    expect(frameAround(tester, 'quoted'), isNull);

    await pumpStoryEditor(tester, controller, editor: RawEditor(controller: controller, blockStyles: const {}));
    expect(frameAround(tester, 'plain'), isNull);
  });
}
