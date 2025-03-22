import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';

class BackupAssetsTableViewer extends StatelessWidget {
  const BackupAssetsTableViewer({
    super.key,
    required this.assets,
  });

  final List<AssetDbModel> assets;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return ListTile(
          title: Text(basename(asset.originalSource)),
          subtitle: Text(
            tr('general.uploaded_to_args', namedArgs: {
              'URL': asset.getGoogleDriveForEmails()?.join(", ") ?? tr('general.na'),
            }),
          ),
        );
      },
    );
  }
}
