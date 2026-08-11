import 'package:storypad/core/services/backups/backup_service_type.dart';

abstract class CloudServiceUser {
  BackupServiceType get serviceType;

  String get identifier;
  String? get displayName;
  String? get photoUrl;
  bool? get autoBackupEnabled;

  String? get globalId;

  /// Key used for `AssetDbModel.cloudDestinations` bookkeeping — distinct
  /// from [identifier] wherever the same account can host more than one
  /// distinct storage location (e.g. Nextcloud's customizable root folder).
  /// Defaults to [identifier] for providers where the account itself *is*
  /// the destination (Drive).
  String get destinationKey => identifier;

  /// Ordered label/value pairs describing this connection's configuration —
  /// rendered on the service's detail screen (see `show_backup_service_content.dart`).
  /// Empty by default: most providers (Drive) have nothing user-configurable
  /// beyond the identifier already shown in the profile tile. Never include
  /// secrets (passwords, tokens) here — this is displayed as plain text.
  List<({String label, String value})> get configuration => const [];
}
