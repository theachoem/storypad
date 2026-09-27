import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/super_editor.dart';
import 'package:storypad_editor_example/pages/raw_editor_page.dart';

void main() {
  testWidgets('the read-only toggle hides embed controls and the toolbar, and back', (tester) async {
    tester.view.physicalSize = const Size(2400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RawEditorPage()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Toggle size'), findsOneWidget);

    await tester.tap(find.byTooltip('Read only'));
    await tester.pumpAndSettle();
    expect(find.byType(SuperReader), findsOneWidget);
    expect(find.byTooltip('Toggle size'), findsNothing);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(SuperEditor), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
