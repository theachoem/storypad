// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropbox_user_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DropboxUserObjectCWProxy {
  DropboxUserObject id(String id);

  DropboxUserObject email(String email);

  DropboxUserObject displayName(String? displayName);

  DropboxUserObject photoUrl(String? photoUrl);

  DropboxUserObject accessToken(String accessToken);

  DropboxUserObject refreshToken(String refreshToken);

  DropboxUserObject accessTokenExpiresAt(DateTime accessTokenExpiresAt);

  DropboxUserObject autoBackupEnabled(bool? autoBackupEnabled);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DropboxUserObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DropboxUserObject(...).copyWith(id: 12, name: "My name")
  /// ```
  DropboxUserObject call({
    String id,
    String email,
    String? displayName,
    String? photoUrl,
    String accessToken,
    String refreshToken,
    DateTime accessTokenExpiresAt,
    bool? autoBackupEnabled,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDropboxUserObject.copyWith(...)` or call `instanceOfDropboxUserObject.copyWith.fieldName(value)` for a single field.
class _$DropboxUserObjectCWProxyImpl implements _$DropboxUserObjectCWProxy {
  const _$DropboxUserObjectCWProxyImpl(this._value);

  final DropboxUserObject _value;

  @override
  DropboxUserObject id(String id) => call(id: id);

  @override
  DropboxUserObject email(String email) => call(email: email);

  @override
  DropboxUserObject displayName(String? displayName) =>
      call(displayName: displayName);

  @override
  DropboxUserObject photoUrl(String? photoUrl) => call(photoUrl: photoUrl);

  @override
  DropboxUserObject accessToken(String accessToken) =>
      call(accessToken: accessToken);

  @override
  DropboxUserObject refreshToken(String refreshToken) =>
      call(refreshToken: refreshToken);

  @override
  DropboxUserObject accessTokenExpiresAt(DateTime accessTokenExpiresAt) =>
      call(accessTokenExpiresAt: accessTokenExpiresAt);

  @override
  DropboxUserObject autoBackupEnabled(bool? autoBackupEnabled) =>
      call(autoBackupEnabled: autoBackupEnabled);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DropboxUserObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DropboxUserObject(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DropboxUserObject call({
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? accessToken = const $CopyWithPlaceholder(),
    Object? refreshToken = const $CopyWithPlaceholder(),
    Object? accessTokenExpiresAt = const $CopyWithPlaceholder(),
    Object? autoBackupEnabled = const $CopyWithPlaceholder(),
  }) {
    return DropboxUserObject(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      photoUrl: photoUrl == const $CopyWithPlaceholder()
          ? _value.photoUrl
          // ignore: cast_nullable_to_non_nullable
          : photoUrl as String?,
      accessToken:
          accessToken == const $CopyWithPlaceholder() || accessToken == null
          ? _value.accessToken
          // ignore: cast_nullable_to_non_nullable
          : accessToken as String,
      refreshToken:
          refreshToken == const $CopyWithPlaceholder() || refreshToken == null
          ? _value.refreshToken
          // ignore: cast_nullable_to_non_nullable
          : refreshToken as String,
      accessTokenExpiresAt:
          accessTokenExpiresAt == const $CopyWithPlaceholder() ||
              accessTokenExpiresAt == null
          ? _value.accessTokenExpiresAt
          // ignore: cast_nullable_to_non_nullable
          : accessTokenExpiresAt as DateTime,
      autoBackupEnabled: autoBackupEnabled == const $CopyWithPlaceholder()
          ? _value.autoBackupEnabled
          // ignore: cast_nullable_to_non_nullable
          : autoBackupEnabled as bool?,
    );
  }
}

extension $DropboxUserObjectCopyWith on DropboxUserObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDropboxUserObject.copyWith(...)` or `instanceOfDropboxUserObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DropboxUserObjectCWProxy get copyWith =>
      _$DropboxUserObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DropboxUserObject _$DropboxUserObjectFromJson(Map<String, dynamic> json) =>
    DropboxUserObject(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['access_token_expires_at'] as String,
      ),
      autoBackupEnabled: json['auto_backup_enabled'] as bool?,
    );

Map<String, dynamic> _$DropboxUserObjectToJson(
  DropboxUserObject instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'display_name': instance.displayName,
  'photo_url': instance.photoUrl,
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'access_token_expires_at': instance.accessTokenExpiresAt.toIso8601String(),
  'auto_backup_enabled': instance.autoBackupEnabled,
};
