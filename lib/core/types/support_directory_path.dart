// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'package:storypad/core/constants/app_constants.dart';

enum SupportDirectoryPath {
  tmp,
  objectbox,
  images,
  audio,
  backups,
  export_assets,
  downloaded_from_firestore,
  ;

  String get relativePath {
    switch (this) {
      case SupportDirectoryPath.tmp:
        return 'tmp';
      case SupportDirectoryPath.objectbox:
        return 'database/objectbox';
      case SupportDirectoryPath.images:
        return 'images';
      case SupportDirectoryPath.audio:
        return 'audio';
      case SupportDirectoryPath.backups:
        return 'backups';
      case SupportDirectoryPath.export_assets:
        return 'export_assets';
      case SupportDirectoryPath.downloaded_from_firestore:
        return 'downloaded_from_firestore';
    }
  }

  String get directoryPath => directory.path;
  Directory get directory => Directory('${kSupportDirectory.path}/$relativePath');

  Future<void> ensureDirectoryExists() async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
}
