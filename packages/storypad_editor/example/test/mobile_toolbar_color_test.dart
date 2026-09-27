import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

/// Regression: same as the link dialog, for a popup menu.
void main() {
  testWidgets('the color menu applies its color even though opening it took focus', (tester) async {
    final controller = await pumpEditorWithToolbar(tester, 'Hello world');
    await focusEditor(tester);
    await selectInFirstBlock(tester, controller, 0, 11);

    await tester.tap(find.byTooltip('Text color'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red').last);
    await tester.pumpAndSettle();

    expect(controller.toMarkdown(), '<span style="color:#e53935ff">Hello world</span>');
    expect(controller.isSelectionHeld.value, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
