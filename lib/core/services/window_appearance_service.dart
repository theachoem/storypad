import 'dart:io';

import 'package:flutter/services.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

/// Matches the desktop window's frame (title bar, window buttons) to the app's light/dark theme rather than the
/// system's. Native side: `macos/Runner/services/WindowAppearanceService.swift`. Other platforms draw no frame of their
/// own (mobile) or don't implement it yet (Linux: its GTK header bar still follows the system theme), so it's a no-op
/// there.
///
/// The window's look itself (on macOS: transparent title bar, hidden title, full-size content) is set in the native
/// project (`MainMenu.xib`), never at runtime: changing it before the first frame resizes the window while Flutter
/// can't draw yet, which makes Impeller fail on launch.
class WindowAppearanceService {
  static const _channel = MethodChannel('default_platform_channel');

  static bool get isSupported => Platform.isMacOS;

  static bool? _dark;

  /// Sets the frame's appearance; only crosses to the native side when it changes (callers set it on every
  /// preferences change).
  static Future<void> setDark(bool dark) async {
    if (!isSupported || _dark == dark) return;
    _dark = dark;
    try {
      await _channel.invokeMethod('WindowAppearanceService.setDark', {'dark': dark});
    } catch (e) {
      _dark = null;
      AppLogger.error('WindowAppearanceService#setDark failed: $e', tag: 'WindowAppearanceService');
    }
  }
}
