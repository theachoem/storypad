import 'package:flutter/material.dart';
import 'package:storypad/core/types/app_product.dart';

class AddOnObject {
  final AppProduct type;
  final String title;
  final String subtitle;
  final String? displayPrice;
  final IconData iconData;
  final int weekdayColor;
  final List<String> demoImages;
  final Future<void> Function(BuildContext context)? onTry;
  final Future<void> Function(BuildContext context) onOpen;

  AddOnObject({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.displayPrice,
    required this.iconData,
    required this.weekdayColor,
    required this.demoImages,
    required this.onTry,
    required this.onOpen,
  });
}
