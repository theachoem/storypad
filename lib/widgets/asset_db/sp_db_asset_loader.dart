import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/assets/db_asset_loader_service.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';
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
          key: ValueKey('SpDbAssetLoader-$relativePath-${backupProvider.currentGoogleUser?.refreshedAt}'),
          relativePath: relativePath,
          currentUser: backupProvider.currentGoogleUser,
          builder: builder,
        );
      },
    );
  }

  static Future<File> load(
    String relativePath,
    GoogleUserObject? currentUser,
  ) async {
    return DbAssetLoaderService.instance.load(
      relativePath: relativePath,
      currentUser: currentUser,
    );
  }

  @override
  State<SpDbAssetLoader> createState() => _SpDbAssetLoaderState();
}

class _SpDbAssetLoaderState extends State<SpDbAssetLoader> {
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
    } catch (e) {
      error = e is GoogleDriveAssetDownloaderException ? e.message : e;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, file, error);
  }
}
