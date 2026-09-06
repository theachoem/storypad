// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';

enum BackupServiceType {
  google_drive(id: 'google_drive', displayName: 'Google Drive', hasGlobalUserId: true),
  nextcloud(id: 'nextcloud', displayName: 'Nextcloud', hasGlobalUserId: true),
  // CloudKit's fetchUserRecordID gives a real, stable per-account identifier
  // — aliased into RevenueCat identity same as Drive/Nextcloud. See
  // ICloudUserObject.globalId.
  icloud(id: 'icloud', displayName: 'iCloud', hasGlobalUserId: true);

  final String id;
  final String displayName;
  final bool hasGlobalUserId;

  bool get googleDrive => this == google_drive;
  bool get nextcloudService => this == nextcloud;
  bool get icloudService => this == icloud;

  /// Only Google Drive syncs for free — Nextcloud and iCloud require Pro.
  bool get isProOnly => this != google_drive;

  const BackupServiceType({
    required this.id,
    required this.displayName,
    required this.hasGlobalUserId,
  });

  /// Get the icon for this service type
  ///
  /// Returns the appropriate IconData for display in UI.
  IconData get icon {
    switch (this) {
      case BackupServiceType.google_drive:
        return SpIcons.googleDrive;
      case BackupServiceType.nextcloud:
        return SpIcons.nextcloud;
      case BackupServiceType.icloud:
        return SpIcons.icloud;
    }
  }
}
