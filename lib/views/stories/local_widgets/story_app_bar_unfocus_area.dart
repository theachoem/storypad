import 'package:flutter/material.dart';

/// An editor's `AppBar.flexibleSpace`: a tap on the app bar's empty space (behind its buttons and title, which keep
/// their taps) hides the keyboard, as tapping outside a text field does -- the iPhone keyboard has no key for it.
class StoryAppBarUnfocusArea extends StatelessWidget {
  const StoryAppBarUnfocusArea({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}
