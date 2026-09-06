import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

part 'icloud_user_object.g.dart';

/// There is no in-app sign-in for iCloud — this object exists purely to track
/// *which* iCloud account is currently active (via [accountId]) and the one
/// real piece of user state, [autoBackupEnabled]. See `ICloudCloudService`
/// for how availability itself is detected.
@CopyWith()
@JsonSerializable()
class ICloudUserObject extends CloudServiceUser {
  /// `CKRecord.ID.recordName` for the default CloudKit container's current
  /// user record (fetched natively via `fetchUserRecordID`) — genuinely
  /// stable across every device signed into the same iCloud account, and
  /// changes when the signed-in account changes. Used directly as both
  /// [destinationKey] and (prefixed) [globalId] — see
  /// docs/app/architecture/backup-sync.md's Identity section for why this
  /// replaced an earlier, per-device `ubiquityIdentityToken`-based attempt.
  final String accountId;

  @override
  final bool? autoBackupEnabled;

  /// Opaque, local-only snapshot of `FileManager.ubiquityIdentityToken` at
  /// the time [accountId] was last confirmed via a successful CloudKit
  /// round-trip (native `fetchIdentityTokenFingerprint`) — never used as
  /// identity itself (CloudKit's `fetchUserRecordID` stays the sole identity
  /// source), only compared for equality. Its one job: when a *later* check
  /// hits a transient CloudKit failure and can't re-confirm [accountId], this
  /// lets `ICloudCloudService` tell "the same account, briefly unreachable"
  /// apart from "the local iCloud sign-in has changed since we last
  /// confirmed this" — persisted (not just in-memory) so the distinction
  /// still holds on a fresh app launch, not only within one running session.
  final String? identityTokenFingerprint;

  @override
  BackupServiceType get serviceType => BackupServiceType.icloud;

  ICloudUserObject({
    required this.accountId,
    required this.autoBackupEnabled,
    this.identityTokenFingerprint,
  });

  /// CloudKit exposes no Apple ID/email for privacy reasons, so this is the
  /// raw [accountId] — deliberately not prefixed with anything like
  /// `icloud@`, since [displayName] ("iCloud") already carries that context
  /// wherever both are shown together (e.g. as the tile's title above this
  /// subtitle).
  @override
  String get identifier => accountId;

  @override
  String? get displayName => 'iCloud';

  @override
  String? get photoUrl => null;

  /// Same account-derived scheme Drive/Nextcloud use, now that [accountId]
  /// is a real, stable-per-account identifier (from CloudKit) rather than a
  /// per-device value: `AssetDbModel.cloudDestinations` bookkeeping written
  /// by one device is correctly recognized as "already uploaded" by every
  /// other device on the same account, AND switching to a genuinely
  /// different iCloud account on one device correctly gets a fresh key
  /// instead of silently trusting the old account's bookkeeping — matching
  /// how Nextcloud's folder-aware override behaves, no special-casing needed.
  @override
  String get destinationKey => accountId;

  /// No longer unconditionally null — CloudKit's `fetchUserRecordID` gives a
  /// real, stable per-account identifier, so iCloud can alias into RevenueCat
  /// identity the same way Drive/Nextcloud do (`InAppPurchaseProvider`
  /// needs no iCloud-specific code for this: `eligibleServices` already just
  /// checks `currentUser?.globalId != null`). Still gated behind
  /// `hasGlobalUserId` for consistency with the other two, even though
  /// iCloud's is always `true`.
  @override
  String? get globalId => serviceType.hasGlobalUserId ? "${serviceType.id}_$accountId" : null;

  Map<String, dynamic> toJson() => _$ICloudUserObjectToJson(this);
  factory ICloudUserObject.fromJson(Map<String, dynamic> json) => _$ICloudUserObjectFromJson(json);
}
