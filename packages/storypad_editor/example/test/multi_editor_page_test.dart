import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor_example/pages/multi_editor_page.dart';

import 'support/pages.dart';

void main() {
  testWidgets('pages can be added and removed; the last one stays', (tester) async {
    await pumpPage(tester, const MultiEditorPage());
    expect(find.byType(RawEditor), findsOneWidget);
    expect(find.byTooltip('Remove page'), findsNothing);

    await tester.tap(find.byTooltip('Add page'));
    await tester.pumpAndSettle();
    expect(find.byType(RawEditor), findsNWidgets(2));

    await tester.tap(find.byTooltip('Remove page').first);
    await tester.pumpAndSettle();
    expect(find.byType(RawEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
