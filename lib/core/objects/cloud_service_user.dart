import 'package:storypad/core/services/backups/backup_service_type.dart';

abstract class CloudServiceUser {
  BackupServiceType get serviceType;
  String get identifier;
  String? get displayName;
  String? get photoUrl;
  bool? get autoBackupEnabled;

  /// The globally-unique platform account ID for this user (e.g. Google account ID).
  /// Used as a RevenueCat identity alias prefix. Returns null for local/dev services
  /// where IDs are not globally unique across users.
  String? get globalId => serviceType.hasGlobalUserId ? "${serviceType.id}_$identifier" : null;
}
