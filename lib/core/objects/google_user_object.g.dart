// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_user_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GoogleUserObjectCWProxy {
  GoogleUserObject id(String id);

  GoogleUserObject email(String email);

  GoogleUserObject displayName(String? displayName);

  GoogleUserObject photoUrl(String? photoUrl);

  GoogleUserObject accessToken(String? accessToken);

  GoogleUserObject refreshedAt(DateTime? refreshedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GoogleUserObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GoogleUserObject(...).copyWith(id: 12, name: "My name")
  /// ````
  GoogleUserObject call({
    String id,
    String email,
    String? displayName,
    String? photoUrl,
    String? accessToken,
    DateTime? refreshedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGoogleUserObject.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGoogleUserObject.copyWith.fieldName(...)`
class _$GoogleUserObjectCWProxyImpl implements _$GoogleUserObjectCWProxy {
  const _$GoogleUserObjectCWProxyImpl(this._value);

  final GoogleUserObject _value;

  @override
  GoogleUserObject id(String id) => this(id: id);

  @override
  GoogleUserObject email(String email) => this(email: email);

  @override
  GoogleUserObject displayName(String? displayName) =>
      this(displayName: displayName);

  @override
  GoogleUserObject photoUrl(String? photoUrl) => this(photoUrl: photoUrl);

  @override
  GoogleUserObject accessToken(String? accessToken) =>
      this(accessToken: accessToken);

  @override
  GoogleUserObject refreshedAt(DateTime? refreshedAt) =>
      this(refreshedAt: refreshedAt);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GoogleUserObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GoogleUserObject(...).copyWith(id: 12, name: "My name")
  /// ````
  GoogleUserObject call({
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? accessToken = const $CopyWithPlaceholder(),
    Object? refreshedAt = const $CopyWithPlaceholder(),
  }) {
    return GoogleUserObject(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      email: email == const $CopyWithPlaceholder()
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
      accessToken: accessToken == const $CopyWithPlaceholder()
          ? _value.accessToken
          // ignore: cast_nullable_to_non_nullable
          : accessToken as String?,
      refreshedAt: refreshedAt == const $CopyWithPlaceholder()
          ? _value.refreshedAt
          // ignore: cast_nullable_to_non_nullable
          : refreshedAt as DateTime?,
    );
  }
}

extension $GoogleUserObjectCopyWith on GoogleUserObject {
  /// Returns a callable class that can be used as follows: `instanceOfGoogleUserObject.copyWith(...)` or like so:`instanceOfGoogleUserObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GoogleUserObjectCWProxy get copyWith => _$GoogleUserObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoogleUserObject _$GoogleUserObjectFromJson(Map<String, dynamic> json) =>
    GoogleUserObject(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      accessToken: json['access_token'] as String?,
      refreshedAt: json['refreshed_at'] == null
          ? null
          : DateTime.parse(json['refreshed_at'] as String),
    );

Map<String, dynamic> _$GoogleUserObjectToJson(GoogleUserObject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'access_token': instance.accessToken,
      'refreshed_at': instance.refreshedAt?.toIso8601String(),
    };
