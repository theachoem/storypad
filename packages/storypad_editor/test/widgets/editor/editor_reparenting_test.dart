import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

import '../../support/controller_helpers.dart';

/// Regression: moving the editor to a new parent (e.g. a responsive layout switching from a Row to a Column) builds the
/// new editor before the old one is disposed, so for a moment both are attached to the controller. That's one editor,
/// not two, and must not be reported as a shared controller.
void main() {
  testWidgets('an editor moved to a new parent keeps working with the same controller', (tester) async {
    final controller = controllerFor('Hello');
    late StateSetter setLayout;
    var wide = true;
    await StoryEditorTester.pump(
      tester,
      controller,
      editor: StatefulBuilder(
        builder: (context, setState) {
          setLayout = setState;
          final editor = Expanded(child: MarkdownEditor(controller: controller));
          return wide ? Row(children: [editor]) : Column(children: [editor]);
        },
      ),
    );

    setLayout(() => wide = false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    setLayout(() => wide = true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(RawEditor), findsOneWidget);
  });
}
