import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/views/root/local_widgets/root_pages_media_query.dart';

/// The pages' screen insets are the same whichever a page reads, the padding or the view padding (as the story pages
/// do, so the keyboard doesn't rebuild them), on every platform: a side set on only one once put the story pages under
/// the big window's sidebar.
void main() {
  const inset = RootPagesMediaQuery.sidebarInset;

  late MediaQueryData seen;

  Future<void> pump(WidgetTester tester, {required bool bigScreen, required MediaQueryData screen}) {
    return tester.pumpWidget(
      MediaQuery(
        data: screen,
        child: RootPagesMediaQuery(
          bigScreen: bigScreen,
          child: Builder(
            builder: (context) {
              seen = MediaQuery.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  void expectSides(EdgeInsets insets, double left, double right, String which) {
    expect(insets.left, left, reason: '$which left');
    expect(insets.right, right, reason: '$which right');
  }

  testWidgets('big window: clear of the sidebar in both the padding and the view padding', (
    tester,
  ) async {
    const screen = MediaQueryData(
      size: Size(1200, 900),
      padding: EdgeInsets.fromLTRB(0, 24, 10, 20),
      viewPadding: EdgeInsets.fromLTRB(0, 24, 10, 20),
    );
    await pump(tester, bigScreen: true, screen: screen);

    expectSides(seen.padding, inset, 10 + inset, 'padding');
    expectSides(seen.viewPadding, inset, 10 + inset, 'view padding');
    expect(seen.padding.top, 24);
    expect(seen.padding.bottom, 20);
    expect(seen.viewPadding.top, 24);
    expect(seen.viewPadding.bottom, 20);
  }, variant: TargetPlatformVariant.all());

  testWidgets('big window with the keyboard up: the sides stay, the view padding keeps its bottom', (tester) async {
    const screen = MediaQueryData(
      size: Size(1200, 900),
      // The keyboard takes the bottom padding; the view padding keeps it.
      padding: EdgeInsets.only(top: 24),
      viewPadding: EdgeInsets.only(top: 24, bottom: 20),
      viewInsets: EdgeInsets.only(bottom: 300),
    );
    await pump(tester, bigScreen: true, screen: screen);

    expectSides(seen.padding, inset, inset, 'padding');
    expectSides(seen.viewPadding, inset, inset, 'view padding');
    expect(seen.padding.bottom, 0);
    expect(seen.viewPadding.bottom, 20);
    expect(seen.viewInsets.bottom, 300);
  });

  testWidgets('small window: the screen\'s own sides (a notch), in both', (tester) async {
    const screen = MediaQueryData(
      size: Size(800, 390),
      padding: EdgeInsets.fromLTRB(44, 0, 44, 21),
      viewPadding: EdgeInsets.fromLTRB(44, 0, 44, 21),
    );
    await pump(tester, bigScreen: false, screen: screen);

    expectSides(seen.padding, 44, 44, 'padding');
    expectSides(seen.viewPadding, 44, 44, 'view padding');
  });
}
