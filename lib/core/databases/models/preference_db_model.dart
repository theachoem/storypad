import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/adapters/objectbox/preferences_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';

part 'preference_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class PreferenceDbModel extends BaseDbModel {
  static final PreferencesBox db = PreferencesBox();

  @override
  final int id;
  final String key;
  final String value;

  final DateTime createdAt;

  @override
  final DateTime updatedAt;
  final String? lastSavedDeviceId;

  @override
  final DateTime? permanentlyDeletedAt;

  PreferenceDbModel({
    required this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
  });

  factory PreferenceDbModel.fromJson(Map<String, dynamic> json) => _$PreferenceDbModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PreferenceDbModelToJson(this);

  bool _cloudViewing = false;
  bool get cloudViewing => _cloudViewing;
  PreferenceDbModel markAsCloudViewing() {
    _cloudViewing = true;
    return this;
  }
}
