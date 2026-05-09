import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/asset_compression_option.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_asset_compression_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class AssetCompressionTile extends StatelessWidget {
  const AssetCompressionTile({
    super.key,
    required this.weekday,
    required this.currentAssetCompression,
    required this.onChanged,
  });

  final int weekday;

  final AssetCompressionOption currentAssetCompression;
  final void Function(AssetCompressionOption assetCompression) onChanged;

  static Widget globalTheme({required int weekday}) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return AssetCompressionTile(
          weekday: weekday,
          currentAssetCompression: provider.preferences.assetCompression,
          onChanged: (assetCompression) => provider.setAssetCompression(assetCompression),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.photo),
      title: Text(tr('list_tile.attachment_compression.title')),
      subtitle: Text(currentAssetCompression.label),
      onTap: () {
        SpAssetCompressionSheet(
          assetCompression: currentAssetCompression,
          onChanged: onChanged,
        ).show(context: context);
      },
    );
  }
}
