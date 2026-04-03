// ignore_for_file: constant_identifier_names

part 'app_legacy_product.dart';

enum AppProduct {
  pro,
  ;

  const AppProduct();

  static List<String> get productIdentifiers => values.map((e) => e.name).toList();

  String get productIdentifier => name;
}
