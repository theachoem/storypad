import 'package:flutter/material.dart';

class AddOnObject {
  final String title;
  final String subtitle;
  final String displayPrice;
  final IconData iconData;
  final int weekdayColor;
  final List<String> demoImages;

  AddOnObject({
    required this.title,
    required this.subtitle,
    required this.displayPrice,
    required this.iconData,
    required this.demoImages,
    required this.weekdayColor,
  });
}
