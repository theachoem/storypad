import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/media_sync_option.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_media_sync_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

/// Which networks media may upload over, plus the escape hatch for media the
/// setting has deferred.
///
/// The "Sync Now" button is part of this tile rather than a tile of its own:
/// it's the corrective action for the state this very setting produces, and it
/// only exists while there's something to correct.
class MediaSyncTile extends StatefulWidget {
  const MediaSyncTile({
    super.key,
    required this.currentMediaSync,
    required this.onChanged,
  });

  final MediaSyncOption currentMediaSync;
  final void Function(MediaSyncOption mediaSync) onChanged;

  static Widget globalTheme() {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return MediaSyncTile(
          currentMediaSync: provider.preferences.mediaSync,
          onChanged: (mediaSync) => provider.setMediaSync(mediaSync),
        );
      },
    );
  }

  @override
  State<MediaSyncTile> createState() => _MediaSyncTileState();
}

class _MediaSyncTileState extends State<MediaSyncTile> {
  @override
  void initState() {
    super.initState();

    // Counting pending media stats every asset file, so it's refreshed on
    // demand here rather than on every database commit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BackupProvider>().refreshPendingMediaCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupProvider>(
      builder: (context, provider, child) {
        // Shown whenever media is pending, not only under wifiOnly: on Wi-Fi +
        // cellular a non-zero count means offline or a failed upload, where the
        // same button is still the fix.
        final hasPending = provider.pendingMediaCount > 0;

        return ListTile(
          leading: const Icon(SpIcons.mediaSync),
          title: Text(context.tr('list_tile.media_sync.title')),
          subtitle: Text(_buildSubtitle(context, provider)),
          trailing: hasPending ? _buildSyncNowButton(context, provider) : null,
          onTap: () {
            SpMediaSyncSheet(
              mediaSync: widget.currentMediaSync,
              onChanged: widget.onChanged,
            ).show(context: context);
          },
        );
      },
    );
  }

  String _buildSubtitle(BuildContext context, BackupProvider provider) {
    final label = widget.currentMediaSync.label;
    if (provider.pendingMediaCount == 0) return label;

    return '$label · ${context.plural('plural.media_more_to_sync', provider.pendingMediaCount)}';
  }

  Widget _buildSyncNowButton(BuildContext context, BackupProvider provider) {
    return OutlinedButton(
      onPressed: provider.syncing
          ? null
          : () => provider.recheckAndSync(
              services: provider.autoBackupServices,
              forceMediaUpload: true,
              context: context,
            ),
      child: Text(context.tr('button.sync_now')),
    );
  }
}
