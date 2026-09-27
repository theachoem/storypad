import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor_example/demo_content.dart';
import 'package:storypad_editor_example/pages/markdown_editor_page.dart';

import 'support/pages.dart';

void main() {
  testWidgets('copying puts the current Markdown on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpPage(tester, const MarkdownEditorPage());
    await tester.tap(find.byTooltip('Copy Markdown'));
    await tester.pumpAndSettle();

    expect(copied, demoMarkdown);
    expect(find.text('Markdown copied'), findsOneWidget);
  });
}
