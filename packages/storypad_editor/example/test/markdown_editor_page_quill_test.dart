import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor_example/pages/markdown_editor_page.dart';

import 'support/pages.dart';

void main() {
  testWidgets('converting Quill JSON loads it as Markdown; invalid JSON shows an error', (tester) async {
    await pumpPage(tester, const MarkdownEditorPage());

    await tester.tap(find.byTooltip('Convert from Quill JSON'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '{"ops": [{"insert": "Hi"}, {"insert": "\\n", "attributes": {"header": 2}}, '
      '{"insert": {"image": "images/a.jpg"}}, {"insert": "\\n"}]}',
    );
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();
    expect(markdownPane(tester), '## Hi\n\n![](images/a.jpg)');

    await tester.tap(find.byTooltip('Convert from Quill JSON'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'not json');
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not valid Quill JSON'), findsOneWidget);
    expect(markdownPane(tester), '## Hi\n\n![](images/a.jpg)', reason: 'unchanged');
  });
}
