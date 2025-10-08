import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/backups_view.dart';
import 'package:storypad/widgets/sp_icons.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        bool hasImage = backupProvider.currentUser?.photoUrl != null;

        return GestureDetector(
          onTap: () => BackupsRoute().push(context),
          child: CircleAvatar(
            radius: 16.0,
            backgroundImage: hasImage ? CachedNetworkImageProvider(backupProvider.currentUser!.photoUrl!) : null,
            child: hasImage ? null : const Icon(SpIcons.profile, size: 16),
          ),
        );
      },
    );
  }
}
