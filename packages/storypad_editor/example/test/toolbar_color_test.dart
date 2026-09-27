import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

void main() {
  testWidgets('the color menu sets and clears a color', (tester) async {
    final controller = await pumpEditorWithToolbar(tester, 'Hello');
    await selectInFirstBlock(tester, controller, 0, 5);

    await tester.tap(find.byTooltip('Text color'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red').last);
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), '<span style="color:#e53935ff">Hello</span>');

    await tester.tap(find.byTooltip('Text color'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None').last);
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), 'Hello');
    expect(controller.isSelectionHeld.value, isFalse, reason: 'every hold released');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
