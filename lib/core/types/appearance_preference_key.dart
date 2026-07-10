/// Identifies a single preference field shown on the Appearance settings page.
///
/// Attach one to any `AppearanceItem` whose tile should be cleared by that
/// page's "Reset" action. Dart's exhaustiveness check on the switch in
/// `DevicePreferencesProvider.resetAppearance()` forces every case here to be
/// handled there too, so a key can't be added without wiring its reset.
enum AppearancePreferenceKey {
  themeMode,
  colorSeed,
  fontSize,
  fontFamily,
  fontWeight,
  dayColors,
  storyTilePreferences,
}
