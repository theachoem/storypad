import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/types/relax_sound_category.dart';

part 'relax_sound_object.g.dart';

@CopyWith()
@JsonSerializable()
class RelaxSoundObject {
  final String translationKey;
  final String svgIconUrlPath;

  // mp3 or wave
  final String soundUrlPath;

  // Base on Cambodia tranditional color by weekday (1 to 7)
  final int dayColor;

  RelaxSoundObject({
    required this.translationKey,
    required this.svgIconUrlPath,
    required this.soundUrlPath,
    this.dayColor = 3,
  }) : assert(dayColor >= 1 && dayColor <= 7);

  String get label => tr(translationKey);

  static List<RelaxSoundObject>? _defaultSoundsList;
  static List<RelaxSoundObject> defaultSoundsList() {
    return _defaultSoundsList ??= defaultSounds().values.expand((e) => e).toList();
  }

  static Map<RelaxSoundCategory, List<RelaxSoundObject>> defaultSounds() {
    return {
      RelaxSoundCategory.rainy: rainySounds(),
      RelaxSoundCategory.water: waterSounds(),
      RelaxSoundCategory.animal: animalSounds(),
    };
  }

  static List<RelaxSoundObject> rainySounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.light_rain',
        svgIconUrlPath: '/relax_sounds/rainy/light_rain.svg',
        soundUrlPath: '/relax_sounds/rainy/light_rain.m4a',
        dayColor: 3,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.rain_on_window',
        svgIconUrlPath: '/relax_sounds/rainy/rain_on_window.svg',
        soundUrlPath: '/relax_sounds/rainy/rain_on_window.m4a',
        dayColor: 4,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.heavy_rain',
        svgIconUrlPath: '/relax_sounds/rainy/heavy_rain.svg',
        soundUrlPath: '/relax_sounds/rainy/heavy_rain.m4a',
        dayColor: 6,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.thunder',
        svgIconUrlPath: '/relax_sounds/rainy/thunder.svg',
        soundUrlPath: '/relax_sounds/rainy/thunder.m4a',
        dayColor: 6,
      ),
    ];
  }

  static List<RelaxSoundObject> waterSounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.ocean_waves',
        svgIconUrlPath: '/relax_sounds/water/ocean_waves.svg',
        soundUrlPath: '/relax_sounds/water/ocean_waves.m4a',
        dayColor: 5,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.river_stream',
        svgIconUrlPath: '/relax_sounds/water/river_stream.svg',
        soundUrlPath: '/relax_sounds/water/river_stream.m4a',
        dayColor: 5,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.droplets',
        svgIconUrlPath: '/relax_sounds/water/droplets.svg',
        soundUrlPath: '/relax_sounds/water/droplets.m4a',
        dayColor: 5,
      ),
    ];
  }

  static List<RelaxSoundObject> animalSounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.night_crickets',
        svgIconUrlPath: '/relax_sounds/animal/night_crickets.svg',
        soundUrlPath: '/relax_sounds/animal/night_crickets.m4a',
        dayColor: 2,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.frogs',
        svgIconUrlPath: '/relax_sounds/animal/frogs.svg',
        soundUrlPath: '/relax_sounds/animal/frogs.m4a',
        dayColor: 1,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.forest_birds',
        svgIconUrlPath: '/relax_sounds/animal/forest_birds.svg',
        soundUrlPath: '/relax_sounds/animal/forest_birds.m4a',
        dayColor: 3,
      ),
    ];
  }

  Map<String, dynamic> toJson() => _$RelaxSoundObjectToJson(this);
  factory RelaxSoundObject.fromJson(Map<String, dynamic> json) => _$RelaxSoundObjectFromJson(json);
}
