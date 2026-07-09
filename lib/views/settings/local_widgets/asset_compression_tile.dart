import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/asset_compression_option.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_asset_compression_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class AssetCompressionTile extends StatelessWidget {
  const AssetCompressionTile({
    super.key,
    required this.currentAssetCompression,
    required this.onChanged,
  });

  final AssetCompressionOption currentAssetCompression;
  final void Function(AssetCompressionOption assetCompression) onChanged;

  static Widget globalTheme() {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return AssetCompressionTile(
          currentAssetCompression: provider.preferences.assetCompression,
          onChanged: (assetCompression) => provider.setAssetCompression(assetCompression),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.photo),
      title: Text(context.tr('list_tile.attachment_compression.title')),
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
