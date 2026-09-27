import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

/// Regression: on mobile, opening the dialog takes focus from the editor, which drops its selection -- so the link
/// used to apply to nothing. The dialog holds the selection.
void main() {
  testWidgets('the link dialog applies its link even though opening it took focus', (tester) async {
    final controller = await pumpEditorWithToolbar(tester, 'Hello world');
    await focusEditor(tester);
    await selectInFirstBlock(tester, controller, 0, 11);

    await tester.tap(find.byTooltip('Link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://example.com');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(controller.toMarkdown(), '[Hello world](https://example.com)');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
