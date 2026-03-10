import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/providers/backup_provider.dart';

class SpDbAssetLoader extends StatefulWidget {
  const SpDbAssetLoader({
    super.key,
    required this.builder,
    required this.currentUser,
    required this.relativePath,
  });

  final String relativePath;
  final GoogleUserObject? currentUser;
  final Widget Function(BuildContext context, File? file, Object? error) builder;

  static Widget withUser({
    required String relativePath,
    required Widget Function(BuildContext context, File? file, Object? error) builder,
  }) {
    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        return SpDbAssetLoader(
          key: ValueKey('SpDbAssetLoader-$relativePath-${backupProvider.currentUser?.hashCode}'),
          relativePath: relativePath,
          currentUser: backupProvider.currentUser,
          builder: builder,
        );
      },
    );
  }

  static Future<File> load(
    String relativePath,
    GoogleUserObject? currentUser,
  ) async {
    int? id = AssetType.parseAssetId(relativePath);
    AssetType? type = AssetType.getTypeFromLink(relativePath);

    if (id == null || type == null) {
      throw StateError('$relativePath is invalid.');
    }

    String filePath = type.getStoragePath(id: id, extension: extension(relativePath));
    File file = File(filePath);

    if (file.existsSync()) return file;

    AssetDbModel? asset = await AssetDbModel.db.find(id);
    File? localFile = asset?.localFile;

    if (asset != null && localFile == null && currentUser != null) {
      final downloader = GoogleDriveAssetDownloaderService();
      final localFilePath = await downloader.downloadAsset(
        asset: asset,
        currentUser: currentUser,
        localFile: localFile,
      );

      return File(localFilePath);
    }

    if (localFile != null) return localFile;
    throw StateError('Asset file for $relativePath not found.');
  }

  @override
  State<SpDbAssetLoader> createState() => _SpDbAssetLoaderState();
}

class _SpDbAssetLoaderState extends State<SpDbAssetLoader> with AutomaticKeepAliveClientMixin {
  String get relativePath => widget.relativePath;
  GoogleUserObject? get currentUser => widget.currentUser;

  File? file;
  Object? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      file = await SpDbAssetLoader.load(relativePath, currentUser);
      setState(() {});
    } catch (e) {
      error = e;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(context, file, error);
  }

  @override
  bool get wantKeepAlive => true;
}
