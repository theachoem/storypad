import 'package:flutter/material.dart';

/// Helper class to detect iPad / iOS multi-tasking or split view
class WindowedDetectorService {
  WindowedDetectorService._(); // private constructor, only static methods

  /// Returns logical device size in points
  static Size getDeviceLogicalSize(BuildContext context) {
    final physicalSize = View.of(context).display.size;
    final devicePixelRatio = View.of(context).display.devicePixelRatio;

    double width = physicalSize.width / devicePixelRatio;
    double height = physicalSize.height / devicePixelRatio;

    // Always match current orientation
    return MediaQuery.orientationOf(context) == Orientation.landscape
        ? Size(width > height ? width : height, width > height ? height : width)
        : Size(width < height ? width : height, width < height ? height : width);
  }

  /// Returns current app window size. Only the size is read (not all of MediaQuery), so a caller doesn't rebuild on
  /// every frame of the keyboard's animation.
  static Size getAppWindowSize(BuildContext context) => MediaQuery.sizeOf(context);

  /// Returns true if app is running in split view / slide over
  static bool isWindowed(BuildContext context, {double threshold = 0.95}) {
    final appSize = getAppWindowSize(context);
    final deviceSize = getDeviceLogicalSize(context);

    // Check if app width or height is smaller than device by threshold
    final isWidthWindowed = appSize.width < deviceSize.width * threshold;
    final isHeightWindowed = appSize.height < deviceSize.height * threshold;

    return isWidthWindowed || isHeightWindowed;
  }

  static bool isBigWindow(BuildContext context) {
    final size = getAppWindowSize(context);
    return isBigWindowFor(size.width, size.height);
  }

  static bool isBigWindowFor(double width, double height) {
    return width >= 720.0 && height >= 500.0;
  }
}
