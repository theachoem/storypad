import 'package:flutter/material.dart';

/// A reusable widget for displaying full-screen content with an image background.
/// Provides proper layering and overlay support for text/UI elements over images.
class SpImageBackgroundScreen extends StatelessWidget {
  const SpImageBackgroundScreen({
    super.key,
    required this.backgroundImage,
    this.overlayColor,
    this.overlayOpacity = 0.3,
    required this.child,
    this.alignment = Alignment.center,
  });

  /// The background image provider (e.g., AssetImage, NetworkImage, etc.)
  final ImageProvider backgroundImage;

  /// Optional overlay color to improve text readability
  /// Defaults to semi-transparent black if not provided
  final Color? overlayColor;

  /// Opacity of the overlay (0.0 - 1.0)
  final double overlayOpacity;

  /// The main content widget to display over the background
  final Widget child;

  /// Alignment of the background image
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: backgroundImage,
          fit: BoxFit.cover,
          alignment: alignment,
        ),
      ),
      child: Stack(
        children: [
          // Overlay for better text readability
          Positioned.fill(
            child: Container(
              color: (overlayColor ?? Colors.black).withValues(
                alpha: overlayOpacity,
              ),
            ),
          ),
          // Main content
          child,
        ],
      ),
    );
  }
}

/// A splash/opening screen widget with decorative gradient overlay.
/// Perfect for app launch screens, onboarding, or welcome screens.
class SpImageBackgroundSplashScreen extends StatelessWidget {
  const SpImageBackgroundSplashScreen({
    super.key,
    required this.backgroundImage,
    required this.title,
    this.subtitle,
    this.actionButtons,
    this.overlayGradient,
    this.titleStyle,
    this.subtitleStyle,
  });

  final ImageProvider backgroundImage;
  final String title;
  final String? subtitle;
  final List<Widget>? actionButtons;
  final Gradient? overlayGradient;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: backgroundImage,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay for better text contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    overlayGradient ??
                    LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(
                          alpha: isDarkMode ? 0.4 : 0.5,
                        ),
                      ],
                    ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top spacing
                  const SizedBox.expand(),
                  // Title and subtitle
                  Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style:
                            titleStyle ??
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style:
                              subtitleStyle ??
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ],
                  ),
                  // Action buttons
                  if (actionButtons != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: actionButtons!,
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
