import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Links open through `RawEditor.onTapLink` (e.g. the app's "open or copy" sheet), not straight in a browser.
void main() {
  Future<List<String>> pumpAndTapLink(
    WidgetTester tester, {
    required bool readOnly,
    String url = 'https://example.com/a',
  }) async {
    final taps = <String>[];
    final controller = controllerFor('[a link to tap]($url)', readOnly: readOnly);
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

  testWidgets('a link without a scheme opens as https, as in the Quill editor', (tester) async {
    expect(await pumpAndTapLink(tester, readOnly: true, url: 'example.com/a'), ['https://example.com/a']);
  });

  test('launchableLinkUrl adds a scheme only when there is none', () {
    expect(launchableLinkUrl('https://a.com'), 'https://a.com');
    expect(launchableLinkUrl('HTTP://a.com'), 'HTTP://a.com');
    expect(launchableLinkUrl('a.com'), 'https://a.com');
    expect(launchableLinkUrl(' www.a.com/x?y=1 '), 'https://www.a.com/x?y=1');
    expect(launchableLinkUrl('me@a.com'), 'mailto:me@a.com');
    expect(launchableLinkUrl('mailto:me@a.com'), 'mailto:me@a.com');
    expect(launchableLinkUrl('tel:+85512345678'), 'tel:+85512345678');
    expect(launchableLinkUrl('a.com/@user'), 'https://a.com/@user');
  });

  testWidgets('editing: a plain tap places the caret instead', (tester) async {
    expect(await pumpAndTapLink(tester, readOnly: false), isEmpty);
  });
}
