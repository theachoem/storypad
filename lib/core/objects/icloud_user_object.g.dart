// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icloud_user_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ICloudUserObjectCWProxy {
  ICloudUserObject accountId(String accountId);

  ICloudUserObject autoBackupEnabled(bool? autoBackupEnabled);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ICloudUserObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ICloudUserObject(...).copyWith(id: 12, name: "My name")
  /// ```
  ICloudUserObject call({String accountId, bool? autoBackupEnabled});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfICloudUserObject.copyWith(...)` or call `instanceOfICloudUserObject.copyWith.fieldName(value)` for a single field.
class _$ICloudUserObjectCWProxyImpl implements _$ICloudUserObjectCWProxy {
  const _$ICloudUserObjectCWProxyImpl(this._value);

  final ICloudUserObject _value;

  @override
  ICloudUserObject accountId(String accountId) => call(accountId: accountId);

  @override
  ICloudUserObject autoBackupEnabled(bool? autoBackupEnabled) =>
      call(autoBackupEnabled: autoBackupEnabled);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ICloudUserObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ICloudUserObject(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ICloudUserObject call({
    Object? accountId = const $CopyWithPlaceholder(),
    Object? autoBackupEnabled = const $CopyWithPlaceholder(),
  }) {
    return ICloudUserObject(
      accountId: accountId == const $CopyWithPlaceholder() || accountId == null
          ? _value.accountId
          // ignore: cast_nullable_to_non_nullable
          : accountId as String,
      autoBackupEnabled: autoBackupEnabled == const $CopyWithPlaceholder()
          ? _value.autoBackupEnabled
          // ignore: cast_nullable_to_non_nullable
          : autoBackupEnabled as bool?,
    );
  }
}

extension $ICloudUserObjectCopyWith on ICloudUserObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfICloudUserObject.copyWith(...)` or `instanceOfICloudUserObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ICloudUserObjectCWProxy get copyWith => _$ICloudUserObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ICloudUserObject _$ICloudUserObjectFromJson(Map<String, dynamic> json) =>
    ICloudUserObject(
      accountId: json['account_id'] as String,
      autoBackupEnabled: json['auto_backup_enabled'] as bool?,
    );

Map<String, dynamic> _$ICloudUserObjectToJson(ICloudUserObject instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'auto_backup_enabled': instance.autoBackupEnabled,
    };
