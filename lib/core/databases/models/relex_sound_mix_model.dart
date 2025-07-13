import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/adapters/objectbox/relax_sound_mixes_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/relax_sound_model.dart';

part 'relex_sound_mix_model.g.dart';

@CopyWith()
@JsonSerializable()
class RelaxSoundMixModel extends BaseDbModel {
  static final RelaxSoundMixesBox db = RelaxSoundMixesBox();

  @override
  final int id;
  final int index;
  final String name;

  final List<RelaxSoundModel> sounds;

  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final DateTime? permanentlyDeletedAt;
  final String? lastSavedDeviceId;

  RelaxSoundMixModel({
    required this.id,
    required this.name,
    required this.sounds,
    required this.createdAt,
    required this.updatedAt,
    this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
    int? index,
  }) : index = index ?? 0;

  @override
  Map<String, dynamic> toJson() => _$RelaxSoundMixModelToJson(this);
  factory RelaxSoundMixModel.fromJson(Map<String, dynamic> json) => _$RelaxSoundMixModelFromJson(json);
}
