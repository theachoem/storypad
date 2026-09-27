import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

void main() {
  testWidgets('inline, block and history buttons act through the controller', (tester) async {
    final controller = await pumpEditorWithToolbar(tester, 'Hello world');
    await selectInFirstBlock(tester, controller, 0, 5);

    await tester.tap(find.byTooltip('Bold'));
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), '**Hello** world');

    await tester.tap(find.byTooltip('Superscript'));
    await tester.tap(find.byTooltip('Subscript'));
    await tester.pumpAndSettle();
    expect(controller.actions.isSubscript, isTrue);

    await tester.tap(find.byTooltip('Undo'));
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), '**Hello** world');

    // Undo resets the selection this test set directly on the composer; select again.
    await selectInFirstBlock(tester, controller, 0, 5);
    await tester.tap(find.byTooltip('Checklist'));
    await tester.tap(find.byTooltip('Indent'));
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), '    - [ ] **Hello** world');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
