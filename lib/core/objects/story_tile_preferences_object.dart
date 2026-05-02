import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'story_tile_preferences_object.g.dart';

@CopyWith()
@JsonSerializable()
class StoryTilePreferencesObject {
  final bool showTime;
  final bool showPageCount;
  final bool showTagLabels;
  final bool showVoiceCount;
  final bool showLocation;
  final int displayCharacterCount;

  StoryTilePreferencesObject({
    bool? showTime,
    bool? showPageCount,
    bool? showTagLabels,
    bool? showVoiceCount,
    bool? showLocation,
    int? displayCharacterCount,
  }) : showTime = showTime ?? true,
       showPageCount = showPageCount ?? true,
       showTagLabels = showTagLabels ?? true,
       showVoiceCount = showVoiceCount ?? true,
       showLocation = showLocation ?? true,
       displayCharacterCount = displayCharacterCount ?? 200;

  // During user editing, we can show all content without limit.
  // displayCharacterCount is ignored.
  static StoryTilePreferencesObject editing() {
    return StoryTilePreferencesObject(
      showPageCount: true,
      showTagLabels: true,
      showTime: true,
    );
  }

  Map<String, dynamic> toJson() => _$StoryTilePreferencesObjectToJson(this);
  factory StoryTilePreferencesObject.fromJson(Map<String, dynamic> json) => _$StoryTilePreferencesObjectFromJson(json);
}
