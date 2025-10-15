// ignore_for_file: constant_identifier_names

enum AppProduct {
  relax_sounds,
  templates,
  period_calendar;

  static List<String> get productIdentifiers => values.map((e) => e.name).toList();

  String get productIdentifier => name;
}
