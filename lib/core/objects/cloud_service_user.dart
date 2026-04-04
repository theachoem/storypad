import 'package:storypad/core/services/backups/backup_service_type.dart';

abstract class CloudServiceUser {
  BackupServiceType get serviceType;

  String get identifier;
  String? get displayName;
  String? get photoUrl;
  bool? get autoBackupEnabled;

  String? get globalId;
}
