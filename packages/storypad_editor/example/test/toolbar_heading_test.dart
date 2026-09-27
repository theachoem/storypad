import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

void main() {
  testWidgets('the heading menu sets a heading, and back to normal', (tester) async {
    final controller = await pumpEditorWithToolbar(tester, 'Title');
    await selectInFirstBlock(tester, controller, 0, 0);

    await tester.tap(find.byTooltip('Heading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heading 2').last);
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), '## Title');

    await tester.tap(find.byTooltip('Heading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Normal').last);
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), 'Title');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
