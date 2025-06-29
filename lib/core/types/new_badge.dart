// ignore_for_file: constant_identifier_names

enum NewBadge {
  community_tile,
  add_on_tile;

  static List<String> get keys => values.map((e) => e.name).toList();
}
