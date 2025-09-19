import 'dart:ui';
import 'package:flutter/material.dart';

class SpPageViewDatas {
  final double translateX1;
  final double? translateX2;
  final double opacity;

  SpPageViewDatas(
    this.translateX1,
    this.translateX2,
    this.opacity,
  );

  factory SpPageViewDatas.fromOffset({
    required int itemIndex,
    required PageController controller,
    required double width,
  }) {
    int currentIndex = controller.page?.toInt() ?? 0;
    bool isCurrentChild = itemIndex == currentIndex;

    double translateX1 = 0;
    double? translateX2 = 0;
    double? opacity = 1;

    double offset = 0;
    offset = (controller.page ?? 0) % 1;

    bool inScope = itemIndex <= currentIndex + 1 && itemIndex >= currentIndex;

    if (inScope) {
      if (isCurrentChild) {
        translateX1 = width * offset;
        opacity = lerpDouble(1, -1, offset);
        translateX2 = lerpDouble(0, -50, offset);
      } else {
        translateX1 = width * (offset - 1);
        opacity = lerpDouble(-1, 1, offset);
        translateX2 = lerpDouble(50, 0, offset);
      }
    }

    if (opacity! < 0) opacity = 0;
    if (opacity > 1) opacity = 1;

    return SpPageViewDatas(translateX1, translateX2, opacity);
  }
}
