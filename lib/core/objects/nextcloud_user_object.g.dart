// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nextcloud_user_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NextcloudUserObjectCWProxy {
  NextcloudUserObject serverUrl(String serverUrl);

  NextcloudUserObject username(String username);

  NextcloudUserObject appPassword(String appPassword);

  NextcloudUserObject autoBackupEnabled(bool? autoBackupEnabled);

  NextcloudUserObject folderName(String? folderName);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `NextcloudUserObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NextcloudUserObject(...).copyWith(id: 12, name: "My name")
  /// ```
  NextcloudUserObject call({
    String serverUrl,
    String username,
    String appPassword,
    bool? autoBackupEnabled,
    String? folderName,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNextcloudUserObject.copyWith(...)` or call `instanceOfNextcloudUserObject.copyWith.fieldName(value)` for a single field.
class _$NextcloudUserObjectCWProxyImpl implements _$NextcloudUserObjectCWProxy {
  const _$NextcloudUserObjectCWProxyImpl(this._value);

  final NextcloudUserObject _value;

  @override
  NextcloudUserObject serverUrl(String serverUrl) => call(serverUrl: serverUrl);

  @override
  NextcloudUserObject username(String username) => call(username: username);

  @override
  NextcloudUserObject appPassword(String appPassword) =>
      call(appPassword: appPassword);

  @override
  NextcloudUserObject autoBackupEnabled(bool? autoBackupEnabled) =>
      call(autoBackupEnabled: autoBackupEnabled);

  @override
  NextcloudUserObject folderName(String? folderName) =>
      call(folderName: folderName);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `NextcloudUserObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NextcloudUserObject(...).copyWith(id: 12, name: "My name")
  /// ```
  NextcloudUserObject call({
    Object? serverUrl = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? appPassword = const $CopyWithPlaceholder(),
    Object? autoBackupEnabled = const $CopyWithPlaceholder(),
    Object? folderName = const $CopyWithPlaceholder(),
  }) {
    return NextcloudUserObject(
      serverUrl: serverUrl == const $CopyWithPlaceholder() || serverUrl == null
          ? _value.serverUrl
          // ignore: cast_nullable_to_non_nullable
          : serverUrl as String,
      username: username == const $CopyWithPlaceholder() || username == null
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      appPassword:
          appPassword == const $CopyWithPlaceholder() || appPassword == null
          ? _value.appPassword
          // ignore: cast_nullable_to_non_nullable
          : appPassword as String,
      autoBackupEnabled: autoBackupEnabled == const $CopyWithPlaceholder()
          ? _value.autoBackupEnabled
          // ignore: cast_nullable_to_non_nullable
          : autoBackupEnabled as bool?,
      folderName: folderName == const $CopyWithPlaceholder()
          ? _value.folderName
          // ignore: cast_nullable_to_non_nullable
          : folderName as String?,
    );
  }
}

extension $NextcloudUserObjectCopyWith on NextcloudUserObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNextcloudUserObject.copyWith(...)` or `instanceOfNextcloudUserObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NextcloudUserObjectCWProxy get copyWith =>
      _$NextcloudUserObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NextcloudUserObject _$NextcloudUserObjectFromJson(Map<String, dynamic> json) =>
    NextcloudUserObject(
      serverUrl: json['server_url'] as String,
      username: json['username'] as String,
      appPassword: json['app_password'] as String,
      autoBackupEnabled: json['auto_backup_enabled'] as bool?,
      folderName: json['folder_name'] as String?,
    );

Map<String, dynamic> _$NextcloudUserObjectToJson(
  NextcloudUserObject instance,
) => <String, dynamic>{
  'server_url': instance.serverUrl,
  'username': instance.username,
  'app_password': instance.appPassword,
  'folder_name': instance.folderName,
  'auto_backup_enabled': instance.autoBackupEnabled,
};
