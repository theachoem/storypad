import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

part 'dropbox_user_object.g.dart';

@CopyWith()
@JsonSerializable()
class DropboxUserObject extends CloudServiceUser {
  /// Dropbox's `account_id` (from `/2/users/get_current_account`) — a real,
  /// stable, cross-device identity, unlike Nextcloud/iCloud's derived IDs.
  final String id;
  final String email;

  @override
  final String? displayName;

  @override
  final String? photoUrl;

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  @override
  final bool? autoBackupEnabled;

  @override
  BackupServiceType get serviceType => BackupServiceType.dropbox;

  DropboxUserObject({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.autoBackupEnabled,
  });

  @override
  String get identifier => email;

  @override
  String? get globalId => serviceType.hasGlobalUserId ? "${serviceType.id}_$id" : null;

  /// A short buffer before the real expiry so a request never races a
  /// just-expired token — mirrors the intent of [GoogleUserObject]'s
  /// refreshed-recently check, but keyed off the token's own expiry instead
  /// of a fixed renewal window, since Dropbox tells us the exact lifetime.
  bool get accessTokenExpiredOrExpiringSoon =>
      DateTime.now().isAfter(accessTokenExpiresAt.subtract(const Duration(minutes: 2)));

  Map<String, dynamic> toJson() => _$DropboxUserObjectToJson(this);
  factory DropboxUserObject.fromJson(Map<String, dynamic> json) => _$DropboxUserObjectFromJson(json);
}
