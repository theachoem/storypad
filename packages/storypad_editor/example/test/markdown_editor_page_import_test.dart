import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor_example/pages/markdown_editor_page.dart';

import 'support/pages.dart';

void main() {
  testWidgets('importing Markdown replaces the document and the live pane', (tester) async {
    await pumpPage(tester, const MarkdownEditorPage());

    await tester.tap(find.byTooltip('Import Markdown'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '# Imported\n\n- [x] done');
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();

    expect(markdownPane(tester), '# Imported\n\n- [x] done');
  });
}
