import 'package:flutter/material.dart';
import 'package:storypad/core/types/app_product.dart';

class AddOnObject {
  final AppProduct type;
  final String title;
  final String subtitle;
  final String? displayPrice;
  final String? displayComparePrice;
  final String? badgeLabel;
  final IconData iconData;
  final int weekdayColor;

  // feature specifically design for female user 🙆‍♀️
  final bool designForFemale;

  final List<String> demoImages;
  final Future<void> Function(BuildContext context)? onTry;
  final Future<void> Function(BuildContext context) onOpen;
  final Future<void> Function()? onPurchased;

  AddOnObject({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.displayPrice,
    required this.displayComparePrice,
    required this.badgeLabel,
    required this.iconData,
    required this.weekdayColor,
    required this.demoImages,
    required this.onTry,
    required this.onOpen,
    required this.onPurchased,
    this.designForFemale = false,
  });
}
