import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that provides edge-to-edge design configuration.
/// This ensures the navigation bar is transparent and content can extend behind it,
/// working consistently across all Android navigation modes (gesture and 3-button).
class EdgeToEdgeWrapper extends StatelessWidget {
  const EdgeToEdgeWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false, // Critical for 3-button navigation edge-to-edge
      ),
      child: child,
    );
  }
}