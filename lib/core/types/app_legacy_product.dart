// ignore_for_file: constant_identifier_names

part of 'app_product.dart';

enum AppLegacyProduct {
  backgrounds,
  voice_journal,
  relax_sounds,
  templates,
  period_calendar,
  markdown_export;

  String get productIdentifier => name;
  static List<String> get productIdentifiers => values.map((e) => e.name).toList();
}
