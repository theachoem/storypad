// ignore_for_file: constant_identifier_names

enum NewBadge {
  community_tile_with_donation,
  community_tile_with_tiktok,
  add_on_tile,
  add_on_tile_with_reward,
  add_on_tile_with_period_calendar,

  none;

  static List<String> get keys => values.map((e) => e.name).toList();
}
