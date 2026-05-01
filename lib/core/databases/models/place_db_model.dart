import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';

part 'place_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class PlaceDbModel extends BaseDbModel {
  final double latitude;
  final double longitude;

  /// Human-readable place name, e.g. "Knowledge Cafe".
  final String? placeName;

  /// City / locality, e.g. "Phnom Penh".
  /// Maps to DayOne `localityName` and Apple Journal `city`.
  final String? locality;

  /// Country name, e.g. "Cambodia".
  final String? country;

  /// Full formatted address string.
  final String? address;

  PlaceDbModel({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.locality,
    this.country,
    this.address,
  });

  SpLatLng get latLng => SpLatLng(latitude, longitude);

  /// Display label: placeName if available, otherwise locality, otherwise coordinates.
  String get displayLabel {
    if (placeName != null) return placeName!;
    if (locality != null) return locality!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  @override
  int get id => 0;

  @override
  DateTime? get updatedAt => null;

  @override
  DateTime? get permanentlyDeletedAt => null;

  factory PlaceDbModel.fromJson(Map<String, dynamic> json) => _$PlaceDbModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PlaceDbModelToJson(this);
}
