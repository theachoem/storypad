// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';

enum BackupServiceType {
  google_drive(id: 'google_drive', displayName: 'Google Drive')
  ;

  final String id;
  final String displayName;

  bool get googleDrive => this == google_drive;

  const BackupServiceType({
    required this.id,
    required this.displayName,
  });

  /// Get the icon for this service type
  ///
  /// Returns the appropriate IconData for display in UI.
  IconData get icon {
    switch (this) {
      case BackupServiceType.google_drive:
        return SpIcons.googleDrive;
    }
  }
}
