import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/assets/backup_asset_downloader_service.dart';
import 'package:storypad/core/services/assets/db_asset_loader_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/providers/backup_provider.dart';

class SpDbAssetLoader extends StatefulWidget {
  const SpDbAssetLoader({
    super.key,
    required this.builder,
    required this.signedInServices,
    required this.relativePath,
  });

  final String relativePath;
  final List<BackupCloudService> signedInServices;
  final Widget Function(BuildContext context, File? file, Object? error) builder;

  static Widget withUser({
    required String relativePath,
    required Widget Function(BuildContext context, File? file, Object? error) builder,
  }) {
    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        return SpDbAssetLoader(
          // Signed-in accounts rarely change mid-session, but a rebuild on
          // reconnect/sign-out must still bust this widget's state — the
          // account set itself (not any single account's refresh timestamp)
          // is what determines which destination is even reachable now.
          key: ValueKey(
            'SpDbAssetLoader-$relativePath-'
            '${backupProvider.signedInServices.map((s) => s.currentUser?.destinationKey).join(',')}',
          ),
          relativePath: relativePath,
          signedInServices: backupProvider.signedInServices,
          builder: builder,
        );
      },
    );
  }

  static Future<File> load(
    String relativePath,
    List<BackupCloudService> signedInServices,
  ) async {
    return DbAssetLoaderService.instance.load(
      relativePath: relativePath,
      signedInServices: signedInServices,
    );
  }

  @override
  State<SpDbAssetLoader> createState() => _SpDbAssetLoaderState();
}

class _SpDbAssetLoaderState extends State<SpDbAssetLoader> {
  String get relativePath => widget.relativePath;
  List<BackupCloudService> get signedInServices => widget.signedInServices;

  File? file;
  Object? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      file = await SpDbAssetLoader.load(relativePath, signedInServices);
    } catch (e) {
      if (e is BackupAssetDownloadException) {
        error = e.message;
      } else if (e is exp.BackupException) {
        error = e.userFriendlyMessage;
      } else {
        error = e;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, file, error);
  }
}
