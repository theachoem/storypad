// ignore_for_file: constant_identifier_names

enum NewBadge {
  community_tile_with_donation,
  add_on_tile,
  add_on_tile_with_reward,
  none;

  static List<String> get keys => values.map((e) => e.name).toList();
}
