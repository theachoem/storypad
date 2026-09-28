import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Links open through `RawEditor.onTapLink` (e.g. the app's "open or copy" sheet), not straight in a browser.
void main() {
  Future<List<String>> pumpAndTapLink(WidgetTester tester, {required bool readOnly}) async {
    final taps = <String>[];
    final controller = controllerFor('[a link to tap](https://example.com/a)', readOnly: readOnly);
    await pumpStoryEditor(
      tester,
      controller,
      editor: RawEditor(controller: controller, onTapLink: taps.add),
    );

    // On the link's first characters (the component is wider than its text).
    await tester.tapAt(tester.getTopLeft(find.byType(TextComponent)) + const Offset(12, 8));
    // Taps resolve once the double-tap window has passed.
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    return taps;
  }

  testWidgets('read-only: tapping a link calls onTapLink with its URL', (tester) async {
    expect(await pumpAndTapLink(tester, readOnly: true), ['https://example.com/a']);
  });

  testWidgets('editing: a plain tap places the caret instead', (tester) async {
    expect(await pumpAndTapLink(tester, readOnly: false), isEmpty);
  });
}
