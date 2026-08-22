import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_map_provider_sheet.dart';
import 'package:storypad/widgets/maps/map_types.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

/// Lets the user pick the map engine by hand.
///
/// Exists because Google Maps is unreachable in some countries and there's no
/// way to tell from inside the app — the SDK initialises perfectly happily and
/// only the tiles never arrive, so a blank map looks identical to a slow one.
class MapProviderTile extends StatelessWidget {
  const MapProviderTile({
    super.key,
    required this.weekday,
    required this.currentMapRenderer,
    required this.onChanged,
  });

  final int weekday;
  final SpMapRenderer currentMapRenderer;
  final void Function(SpMapRenderer value) onChanged;

  static Widget globalTheme({required int weekday}) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        // Shown where Google Maps can't load — but also to anyone who has
        // already switched, wherever they are now. Hiding it the moment they
        // travel out of the region would be a one-way door.
        final bool visible =
            SpMapRenderer.selectable(kLocalTimezone) || provider.preferences.mapRenderer != null || kDebugMode;
        if (!visible) return const SizedBox.shrink();

        return MapProviderTile(
          weekday: weekday,
          currentMapRenderer: provider.mapRenderer,
          onChanged: (value) => provider.setMapRenderer(value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.map),
      title: Text(context.tr('list_tile.map_provider.title')),
      subtitle: Text(currentMapRenderer.label),
      onTap: () {
        SpMapProviderSheet(
          mapRenderer: currentMapRenderer,
          onChanged: onChanged,
        ).show(context: context);
      },
    );
  }
}
