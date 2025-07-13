import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'relax_sound_model.g.dart';

@CopyWith()
@JsonSerializable()
class RelaxSoundModel {
  final String soundUrlPath;
  final double volume;

  RelaxSoundModel({
    required this.soundUrlPath,
    required this.volume,
  });

  Map<String, dynamic> toJson() => _$RelaxSoundModelToJson(this);
  factory RelaxSoundModel.fromJson(Map<String, dynamic> json) => _$RelaxSoundModelFromJson(json);
}
