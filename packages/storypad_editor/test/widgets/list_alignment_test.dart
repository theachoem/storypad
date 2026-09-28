import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// A Quill story can align any line; list items and tasks render their alignment (stock super_editor ignores it).
void main() {
  for (final readOnly in [false, true]) {
    testWidgets('aligned list items and tasks render aligned${readOnly ? ' (read-only)' : ''}', (tester) async {
      final controller = controllerFor(
        '<div style="text-align:center">\n\n- bullet\n1. ordered\n- [ ] task\n\n</div>\n\n- plain',
        readOnly: readOnly,
      );
      await pumpStoryEditor(tester, controller);

      TextAlign? alignOf(String text) => tester
          .widgetList<TextComponent>(find.byType(TextComponent))
          .firstWhere((component) => component.text.toPlainText() == text)
          .textAlign;

      expect(alignOf('bullet'), TextAlign.center);
      expect(alignOf('ordered'), TextAlign.center);
      expect(alignOf('task'), TextAlign.center);
      expect(alignOf('plain'), TextAlign.left);
    });
  }
}
