// Reference:
// https://github.com/flutter/flutter/issues/41472

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpSnapScrollPhysics extends PageScrollPhysics {
  final double Function(ScrollMetrics position) itemWidthGetter;
  final void Function(double index)? onSnap;

  const SpSnapScrollPhysics({
    required this.itemWidthGetter,
    this.onSnap,
    super.parent,
  });

  @override
  SpSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SpSnapScrollPhysics(
      parent: buildParent(ancestor),
      itemWidthGetter: itemWidthGetter,
      onSnap: onSnap,
    );
  }

  double getCurrentItemWidth(ScrollMetrics position) {
    return itemWidthGetter(position);
  }

  double _getPixels(ScrollMetrics position, double item) {
    return min(max(item * getCurrentItemWidth(position), position.minScrollExtent), position.maxScrollExtent);
  }

  double _getTargetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    double item = position.pixels / getCurrentItemWidth(position);

    if (velocity < -tolerance.velocity) {
      item -= 1 * 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 1 * 0.5;
    }

    return _getPixels(position, item.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    Simulation? simulation = _createBallisticSimulation(position, velocity);

    return simulation;
  }

  Simulation? _createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      notifySnap(target, position);
      return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
    }
    return null;
  }

  void notifySnap(double target, ScrollMetrics position) {
    onSnap?.call(target / getCurrentItemWidth(position));
    HapticFeedback.selectionClick();
  }

  @override
  bool get allowImplicitScrolling => false;
}
