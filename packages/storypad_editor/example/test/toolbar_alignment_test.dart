import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/toolbar_harness.dart';

void main() {
  testWidgets('the alignment menu aligns the paragraph', (tester) async {
    final controller = await pumpEditorWithToolbar(tester, 'Hello');
    await selectInFirstBlock(tester, controller, 0, 0);

    await tester.tap(find.byTooltip('Alignment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('center').last);
    await tester.pumpAndSettle();

    expect(controller.toMarkdown(), '<div style="text-align:center">\n\nHello\n\n</div>');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
