import 'package:flutter/material.dart';
import 'package:storypad/core/services/windowed_detector_service.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

// On big screen, root view will modify the default padding which pushes FAB too far to the edge.
// This custom FAB location will add extra offset to compensate for that.
//
// Return default location on small screen.
class SpFabLocation extends StandardFabLocation with FabEndOffsetX, FabFloatOffsetY {
  const SpFabLocation();

  static FloatingActionButtonLocation endFloat(BuildContext context) {
    // When in a nested navigation, we want to keep the default behavior as it consider smaller width or nested in a screen.
    return WindowedDetectorService.isBigWindow(context) && SpNestedNavigation.maybeOf(context) == null
        ? const SpFabLocation()
        : FloatingActionButtonLocation.endFloat;
  }

  @override
  double getOffsetX(ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    return switch (scaffoldGeometry.textDirection) {
      TextDirection.rtl => _leftOffsetX(scaffoldGeometry, adjustment) + 88 - scaffoldGeometry.minViewPadding.bottom,
      TextDirection.ltr => _rightOffsetX(scaffoldGeometry, adjustment) + 88 - scaffoldGeometry.minViewPadding.bottom,
    };
  }

  /// Calculates x-offset for left-aligned [FloatingActionButtonLocation]s.
  double _leftOffsetX(ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    return kFloatingActionButtonMargin + scaffoldGeometry.minInsets.left - adjustment;
  }

  /// Calculates x-offset for right-aligned [FloatingActionButtonLocation]s.
  double _rightOffsetX(ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    return scaffoldGeometry.scaffoldSize.width -
        kFloatingActionButtonMargin -
        scaffoldGeometry.minInsets.right -
        scaffoldGeometry.floatingActionButtonSize.width +
        adjustment;
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endFloat';
}
