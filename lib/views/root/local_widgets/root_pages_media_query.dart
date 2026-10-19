import 'package:flutter/material.dart';

/// The screen insets the pages navigator's routes see: on a big window, 88 on each side, clear of the sidebar.
///
/// Set on both the padding and the view padding. Pages read either -- the view padding where they shouldn't rebuild
/// as the keyboard moves (the padding's bottom changes with it) -- so a side set on only one is lost on the screens
/// that read the other (as the story pages once lost theirs, running under the sidebar).
class RootPagesMediaQuery extends StatelessWidget {
  const RootPagesMediaQuery({
    super.key,
    required this.bigScreen,
    required this.child,
  });

  static const double sidebarInset = 88;

  final bool bigScreen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenPadding = mediaQuery.padding;

    final double left = bigScreen ? sidebarInset : screenPadding.left;
    final double right = bigScreen ? screenPadding.right + sidebarInset : screenPadding.right;

    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: screenPadding.copyWith(left: left, right: right),
        viewPadding: mediaQuery.viewPadding.copyWith(left: left, right: right),
      ),
      child: child,
    );
  }
}
