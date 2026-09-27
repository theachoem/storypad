import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps an example page on a tall surface.
Future<void> pumpPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

/// The Markdown editor page's live Markdown pane.
String markdownPane(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byKey(const ValueKey('markdown-pane'))).data!;
