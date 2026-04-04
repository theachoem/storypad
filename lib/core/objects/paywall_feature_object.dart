// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum PaywallFeature {
  relax_sounds,
  voice_journal,
  markdown_export,
  pinned_notes,
  templates,
  writing_stats,
  backgrounds,
  auto_backups,
  period_calendar,
}

class PaywallFeatureObject {
  final PaywallFeature type;
  final String title;
  final String subtitle;
  final IconData iconData;
  final int weekdayColor;

  // feature specifically design for female user 🙆‍♀️
  final bool designForFemale;

  final List<String> demoImages;
  final Future<void> Function(BuildContext context)? onOpen;

  PaywallFeatureObject({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.weekdayColor,
    required this.demoImages,
    required this.onOpen,
    this.designForFemale = false,
  });

  static List<PaywallFeatureObject> getAll() {
    return [];
  }
}
