import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/types/appearance_preference_key.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/day_colors/day_colors_view.dart';
import 'package:storypad/views/settings/local_widgets/app_icon_tile.dart';
import 'package:storypad/views/settings/local_widgets/color_seed_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_family_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_size_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_weight_tile.dart';
import 'package:storypad/views/settings/local_widgets/quick_actions_tile.dart';
import 'package:storypad/views/settings/local_widgets/story_tile_preferences_tile.dart';
import 'package:storypad/views/settings/local_widgets/theme_mode_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

/// A single tile on the Appearance page.
///
/// [resetKey] is `null` for tiles with nothing to reset (e.g. `AppIconTile`,
/// `QuickActionsTile` — app shortcuts aren't a resettable preference).
class AppearanceItem {
  const AppearanceItem({
    required this.builder,
    this.resetKey,
  });

  final WidgetBuilder builder;
  final AppearancePreferenceKey? resetKey;
}

class AppearanceSection {
  const AppearanceSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<AppearanceItem> items;
}

class AppearanceViewModel extends ChangeNotifier with DisposeAwareMixin {
  AppearanceViewModel(BuildContext context) : sections = _buildSections();

  final List<AppearanceSection> sections;

  Set<AppearancePreferenceKey> get resettableKeys {
    return sections.expand((section) => section.items).map((item) => item.resetKey).nonNulls.toSet();
  }

  void reset(BuildContext context) {
    context.read<DevicePreferencesProvider>().resetAppearance(resettableKeys);
  }

  static List<AppearanceSection> _buildSections() {
    return [
      AppearanceSection(
        title: tr("general.appearance"),
        items: [
          AppearanceItem(
            builder: (context) => ThemeModeTile.globalTheme(weekday: 1),
            resetKey: .themeMode,
          ),
          AppearanceItem(
            builder: (context) => const ColorSeedTile(),
            resetKey: .colorSeed,
          ),
          if (kStoryPad) const AppearanceItem(builder: _buildAppIconTile),
        ],
      ),
      AppearanceSection(
        title: tr("general.text"),
        items: [
          AppearanceItem(
            builder: (context) => FontSizeTile.globalTheme(weekday: 2),
            resetKey: .fontSize,
          ),
          AppearanceItem(
            builder: (context) => FontFamilyTile.globalTheme(weekday: 3),
            resetKey: .fontFamily,
          ),
          AppearanceItem(
            builder: (context) => FontWeightTile.globalTheme(weekday: 4),
            resetKey: .fontWeight,
          ),
        ],
      ),
      AppearanceSection(
        title: tr("general.advanced"),
        items: [
          const AppearanceItem(
            builder: _buildDayColorTile,
            resetKey: .dayColors,
          ),
          const AppearanceItem(
            builder: _buildStoryTilePreferencesTile,
            resetKey: .storyTilePreferences,
          ),
          if (kSupportQuickActions) const AppearanceItem(builder: _buildQuickActionsTile),
        ],
      ),
    ];
  }

  static Widget _buildAppIconTile(BuildContext context) => const AppIconTile();

  static Widget _buildStoryTilePreferencesTile(BuildContext context) => const StoryTilePreferencesTile(weekday: 6);

  static Widget _buildQuickActionsTile(BuildContext context) => QuickActionsTile();

  static Widget _buildDayColorTile(BuildContext context) {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, inAppPurchaseProvider, child) {
        final locked = !inAppPurchaseProvider.isProUser;
        return ListTile(
          trailing: locked ? const Icon(SpIcons.lock) : null,
          leading: const SpSettingIconBadge(weekday: 5, icon: SpIcons.theme),
          title: Text(context.tr('list_tile.day_colors.title')),
          onTap: () => const DayColorsRoute().push(context),
        );
      },
    );
  }
}
