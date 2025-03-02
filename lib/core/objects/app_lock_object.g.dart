// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppLockObjectCWProxy {
  AppLockObject pin(String? pin);

  AppLockObject enabledBiometric(bool? enabledBiometric);

  AppLockObject securityAnswers(Map<AppLockQuestion, String>? securityAnswers);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppLockObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppLockObject(...).copyWith(id: 12, name: "My name")
  /// ````
  AppLockObject call({
    String? pin,
    bool? enabledBiometric,
    Map<AppLockQuestion, String>? securityAnswers,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppLockObject.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppLockObject.copyWith.fieldName(...)`
class _$AppLockObjectCWProxyImpl implements _$AppLockObjectCWProxy {
  const _$AppLockObjectCWProxyImpl(this._value);

  final AppLockObject _value;

  @override
  AppLockObject pin(String? pin) => this(pin: pin);

  @override
  AppLockObject enabledBiometric(bool? enabledBiometric) =>
      this(enabledBiometric: enabledBiometric);

  @override
  AppLockObject securityAnswers(
          Map<AppLockQuestion, String>? securityAnswers) =>
      this(securityAnswers: securityAnswers);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppLockObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppLockObject(...).copyWith(id: 12, name: "My name")
  /// ````
  AppLockObject call({
    Object? pin = const $CopyWithPlaceholder(),
    Object? enabledBiometric = const $CopyWithPlaceholder(),
    Object? securityAnswers = const $CopyWithPlaceholder(),
  }) {
    return AppLockObject(
      pin: pin == const $CopyWithPlaceholder()
          ? _value.pin
          // ignore: cast_nullable_to_non_nullable
          : pin as String?,
      enabledBiometric: enabledBiometric == const $CopyWithPlaceholder()
          ? _value.enabledBiometric
          // ignore: cast_nullable_to_non_nullable
          : enabledBiometric as bool?,
      securityAnswers: securityAnswers == const $CopyWithPlaceholder()
          ? _value.securityAnswers
          // ignore: cast_nullable_to_non_nullable
          : securityAnswers as Map<AppLockQuestion, String>?,
    );
  }
}

extension $AppLockObjectCopyWith on AppLockObject {
  /// Returns a callable class that can be used as follows: `instanceOfAppLockObject.copyWith(...)` or like so:`instanceOfAppLockObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppLockObjectCWProxy get copyWith => _$AppLockObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppLockObject _$AppLockObjectFromJson(Map<String, dynamic> json) =>
    AppLockObject(
      pin: json['pin'] as String?,
      enabledBiometric: json['enabled_biometric'] as bool?,
      securityAnswers: (json['security_answers'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry($enumDecode(_$AppLockQuestionEnumMap, k), e as String),
      ),
    );

Map<String, dynamic> _$AppLockObjectToJson(AppLockObject instance) =>
    <String, dynamic>{
      'pin': instance.pin,
      'enabled_biometric': instance.enabledBiometric,
      'security_answers': instance.securityAnswers
          ?.map((k, e) => MapEntry(_$AppLockQuestionEnumMap[k]!, e)),
    };

const _$AppLockQuestionEnumMap = {
  AppLockQuestion.name_of_your_first_pet: 'name_of_your_first_pet',
  AppLockQuestion.city_or_town_your_were_born: 'city_or_town_your_were_born',
  AppLockQuestion.favorite_childhood_friend: 'favorite_childhood_friend',
  AppLockQuestion.favorite_color: 'favorite_color',
  AppLockQuestion.name_of_elementary_school: 'name_of_elementary_school',
  AppLockQuestion.city_or_town_your_parent_met: 'city_or_town_your_parent_met',
  AppLockQuestion.name_of_your_first_teacher: 'name_of_your_first_teacher',
};
