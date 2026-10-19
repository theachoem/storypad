part of 'android_popover_toolbar.dart';

// Kept byte-for-byte with upstream (see android_popover_toolbar.dart), so its lints are its own:
// ignore_for_file: use_key_in_widget_constructors

// The Material-styled toolbar outline. Fill it with any widgets you want. No
// overflow ability.
class AndroidPopoverToolbarContainer extends StatelessWidget {
  const AndroidPopoverToolbarContainer({required this.child});

  final Widget child;

  // These colors were taken from a screenshot of a Pixel 6 emulator running
  // Android API level 35.
  static const Color _defaultColorLight = Color(0xFFE2E2EA);
  static const Color _defaultColorDark = Color(0xFF33343A);

  static Color _getColor(ColorScheme colorScheme) {
    return switch (colorScheme.brightness) {
      Brightness.light => _defaultColorLight,
      Brightness.dark => _defaultColorDark,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      // This value was eyeballed to match the native text selection menu on
      // a Pixel 6 emulator running Android API level 34.
      borderRadius: const BorderRadius.all(Radius.circular(_kToolbarHeight / 2)),
      clipBehavior: Clip.antiAlias,
      color: _getColor(theme.colorScheme),
      elevation: 1.0,
      type: MaterialType.card,
      child: child,
    );
  }
}
