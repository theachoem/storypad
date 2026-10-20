import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/widgets/pages_toolbar/sp_pages_toolbar.dart';

/// The Scaffold takes the bottom safe area off its body for its bottom bar, so with no toolbar shown (managing pages,
/// or no page focused) the bar still keeps that space: the page grid and its delete bin stay clear of the home
/// indicator.
void main() {
  const bottomInset = 34.0;

  /// The space below the body.
  Future<double> spaceBelowBody(WidgetTester tester, {required bool managingPage}) async {
    final body = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Scaffold(
            body: SizedBox.expand(key: body),
            bottomNavigationBar: SpPagesToolbar(pages: const [], backgroundColor: null, managingPage: managingPage),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(Scaffold)).height - tester.getBottomLeft(find.byKey(body)).dy;
  }

  testWidgets('no page focused: the body ends above the home indicator', (tester) async {
    expect(await spaceBelowBody(tester, managingPage: false), bottomInset);
  });

  testWidgets('managing pages: the body ends above the home indicator', (tester) async {
    expect(await spaceBelowBody(tester, managingPage: true), bottomInset);
  });
}
