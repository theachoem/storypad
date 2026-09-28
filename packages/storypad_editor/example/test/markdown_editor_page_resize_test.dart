import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor_example/pages/markdown_editor_page.dart';

/// Regression: crossing the page's wide/narrow breakpoint moved the editor to a new parent, which briefly attached two
/// editors to one controller and tripped the "one editor per controller" check.
void main() {
  testWidgets('resizing across the layout breakpoint keeps the same editor', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MarkdownEditorPage()));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(RawEditor));

    tester.view.physicalSize = const Size(600, 1600);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.state(find.byType(RawEditor)), same(state), reason: 'moved, not rebuilt');

    tester.view.physicalSize = const Size(1200, 1600);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
