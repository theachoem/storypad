import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/root_provider.dart';

/// Applies an overlay [Theme] tuned for map controls (AppBar, FAB, buttons)
/// drawn on top of a map tile layer.
///
/// Each [SpMapAdapter] exposes [SpMapAdapter.overlayBrightness] to declare
/// whether its tiles appear light or dark for a given tile style. Pass that
/// value here, and this widget generates an appropriate [ColorScheme] so the
/// controls remain legible regardless of the underlying map.
///
/// ```dart
/// SpMapOverlayTheme(
///   brightness: mapAdapter.overlayBrightness(viewModel.tileStyle),
///   child: AppBar(...),
/// )
/// ```
class SpMapOverlayTheme extends StatefulWidget {
  const SpMapOverlayTheme({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  State<SpMapOverlayTheme> createState() => _SpMapOverlayThemeState();
}

class _SpMapOverlayThemeState extends State<SpMapOverlayTheme> {
  late RootProvider rootProvider = context.read<RootProvider>();

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootProvider.setSideBarColorScheme(null);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = Theme.of(context).colorScheme.primary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: widget.brightness,
      dynamicSchemeVariant: .monochrome,
    );

    final baseTheme = AppTheme.getTheme(
      colorScheme: colorScheme,
      fontFamily: context.read<DevicePreferencesProvider>().preferences.fontFamily,
      fontWeight: context.read<DevicePreferencesProvider>().preferences.fontWeight,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    final theme = baseTheme.copyWith(
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: CircleBorder(
            side: BorderSide(color: baseTheme.dividerColor),
          ),
          backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
          foregroundColor: colorScheme.onSurface,
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootProvider.setSideBarColorScheme(colorScheme);
    });

    return Theme(
      data: theme,
      child: widget.child,
    );
  }
}
