// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaceDbModelCWProxy {
  PlaceDbModel latitude(double latitude);

  PlaceDbModel longitude(double longitude);

  PlaceDbModel placeName(String? placeName);

  PlaceDbModel locality(String? locality);

  PlaceDbModel country(String? country);

  PlaceDbModel address(String? address);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PlaceDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlaceDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  PlaceDbModel call({
    double latitude,
    double longitude,
    String? placeName,
    String? locality,
    String? country,
    String? address,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlaceDbModel.copyWith(...)` or call `instanceOfPlaceDbModel.copyWith.fieldName(value)` for a single field.
class _$PlaceDbModelCWProxyImpl implements _$PlaceDbModelCWProxy {
  const _$PlaceDbModelCWProxyImpl(this._value);

  final PlaceDbModel _value;

  @override
  PlaceDbModel latitude(double latitude) => call(latitude: latitude);

  @override
  PlaceDbModel longitude(double longitude) => call(longitude: longitude);

  @override
  PlaceDbModel placeName(String? placeName) => call(placeName: placeName);

  @override
  PlaceDbModel locality(String? locality) => call(locality: locality);

  @override
  PlaceDbModel country(String? country) => call(country: country);

  @override
  PlaceDbModel address(String? address) => call(address: address);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PlaceDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlaceDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  PlaceDbModel call({
    Object? latitude = const $CopyWithPlaceholder(),
    Object? longitude = const $CopyWithPlaceholder(),
    Object? placeName = const $CopyWithPlaceholder(),
    Object? locality = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
  }) {
    return PlaceDbModel(
      latitude: latitude == const $CopyWithPlaceholder() || latitude == null
          ? _value.latitude
          // ignore: cast_nullable_to_non_nullable
          : latitude as double,
      longitude: longitude == const $CopyWithPlaceholder() || longitude == null
          ? _value.longitude
          // ignore: cast_nullable_to_non_nullable
          : longitude as double,
      placeName: placeName == const $CopyWithPlaceholder()
          ? _value.placeName
          // ignore: cast_nullable_to_non_nullable
          : placeName as String?,
      locality: locality == const $CopyWithPlaceholder()
          ? _value.locality
          // ignore: cast_nullable_to_non_nullable
          : locality as String?,
      country: country == const $CopyWithPlaceholder()
          ? _value.country
          // ignore: cast_nullable_to_non_nullable
          : country as String?,
      address: address == const $CopyWithPlaceholder()
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String?,
    );
  }
}

extension $PlaceDbModelCopyWith on PlaceDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlaceDbModel.copyWith(...)` or `instanceOfPlaceDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaceDbModelCWProxy get copyWith => _$PlaceDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceDbModel _$PlaceDbModelFromJson(Map<String, dynamic> json) => PlaceDbModel(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  placeName: json['place_name'] as String?,
  locality: json['locality'] as String?,
  country: json['country'] as String?,
  address: json['address'] as String?,
);

Map<String, dynamic> _$PlaceDbModelToJson(PlaceDbModel instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'place_name': instance.placeName,
      'locality': instance.locality,
      'country': instance.country,
      'address': instance.address,
    };
