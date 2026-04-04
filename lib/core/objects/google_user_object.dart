// ignore_for_file: constant_identifier_names

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

part 'google_user_object.g.dart';

@CopyWith()
@JsonSerializable()
class GoogleUserObject extends CloudServiceUser {
  final String id;
  final String email;

  @override
  final String? displayName;

  @override
  final String? photoUrl;

  final String? accessToken;
  final DateTime? refreshedAt;

  @override
  final bool? autoBackupEnabled;

  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

  GoogleUserObject({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.accessToken,
    required this.refreshedAt,
    required this.autoBackupEnabled,
  });

  @override
  String get identifier => email;

  /// The globally-unique platform account ID for this user (e.g. Google account ID).
  /// Used as a RevenueCat identity alias prefix. Returns null for local/dev services
  /// where IDs are not globally unique across users.
  @override
  String? get globalId => serviceType.hasGlobalUserId ? "${serviceType.id}_$id" : null;

  String? get bigImageUrl => _maximizeImage(photoUrl);

  static const int RENEWAL_THRESHOLD_MINUTES = 55;

  String? _maximizeImage(String? imageUrl) {
    if (imageUrl == null) return null;
    String lowQuality = "s96-c";
    String highQuality = "s0";
    return imageUrl.replaceAll(lowQuality, highQuality);
  }

  bool isRefreshedRecently() {
    if (refreshedAt == null) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(refreshedAt!);
    return difference.inMinutes < RENEWAL_THRESHOLD_MINUTES;
  }

  Map<String, String> get authHeaders {
    return <String, String>{
      'Authorization': 'Bearer $accessToken',
      'X-Goog-AuthUser': '0',
    };
  }

  Map<String, dynamic> toJson() => _$GoogleUserObjectToJson(this);
  factory GoogleUserObject.fromJson(Map<String, dynamic> json) => _$GoogleUserObjectFromJson(json);
}
