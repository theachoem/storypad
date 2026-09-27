import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

void main() {
  testWidgets('the link dialog adds, pre-fills when editing, and an empty URL removes', (tester) async {
    final controller = await pumpEditorWithToolbar(tester, 'Hello world');
    await selectInFirstBlock(tester, controller, 0, 5);

    await tester.tap(find.byTooltip('Link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'https://a.com');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), '[Hello](https://a.com) world');

    await tester.tap(find.byTooltip('Link'));
    await tester.pumpAndSettle();
    expect(find.text('Edit link'), findsOneWidget);
    expect(find.text('https://a.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), 'Hello world');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
