import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/types/relax_sound_category.dart';

part 'relax_sound_object.g.dart';

@CopyWith()
@JsonSerializable()
class RelaxSoundObject {
  static const String baseUrl = "https://storypad.juniorise.com";

  final String translationKey;
  final String svgIconPath;

  // mp3 or wave
  final String soundPath;

  // Base on Cambodia tranditional color by weekday (1 to 7)
  final int dayColor;

  RelaxSoundObject({
    required this.translationKey,
    required this.svgIconPath,
    required this.soundPath,
    this.dayColor = 3,
  }) : assert(dayColor >= 1 && dayColor <= 7);

  String get label => tr(translationKey);
  String get svgIconUrl => baseUrl + svgIconPath;
  String get soundUrl => baseUrl + soundPath;

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
        svgIconPath: '/relax_sounds/rainy/light_rain.svg',
        soundPath: '/relax_sounds/rainy/light_rain.wav',
        dayColor: 3,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.rain_on_window',
        svgIconPath: '/relax_sounds/rainy/rain_on_window.svg',
        soundPath: '/relax_sounds/rainy/rain_on_window.wav',
        dayColor: 4,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.heavy_rain',
        svgIconPath: '/relax_sounds/rainy/heavy_rain.svg',
        soundPath: '/relax_sounds/rainy/heavy_rain.wav',
        dayColor: 6,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.thunder',
        svgIconPath: '/relax_sounds/rainy/thunder.svg',
        soundPath: '/relax_sounds/rainy/thunder.wav',
        dayColor: 6,
      ),
    ];
  }

  static List<RelaxSoundObject> waterSounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.ocean_waves',
        svgIconPath: '/relax_sounds/water/ocean_waves.svg',
        soundPath: '/relax_sounds/water/ocean_waves.wav',
        dayColor: 5,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.river_stream',
        svgIconPath: '/relax_sounds/water/river_stream.svg',
        soundPath: '/relax_sounds/water/river_stream.wav',
        dayColor: 5,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.droplets',
        svgIconPath: '/relax_sounds/water/droplets.svg',
        soundPath: '/relax_sounds/water/droplets.wav',
        dayColor: 5,
      ),
    ];
  }

  static List<RelaxSoundObject> animalSounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.night_crickets',
        svgIconPath: '/relax_sounds/animal/night_crickets.svg',
        soundPath: '/relax_sounds/animal/night_crickets.wav',
        dayColor: 2,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.frogs',
        svgIconPath: '/relax_sounds/animal/frogs.svg',
        soundPath: '/relax_sounds/animal/frogs.wav',
        dayColor: 1,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.forest_birds',
        svgIconPath: '/relax_sounds/animal/forest_birds.svg',
        soundPath: '/relax_sounds/animal/forest_birds.wav',
        dayColor: 3,
      ),
    ];
  }

  Map<String, dynamic> toJson() => _$RelaxSoundObjectToJson(this);
  factory RelaxSoundObject.fromJson(Map<String, dynamic> json) => _$RelaxSoundObjectFromJson(json);
}
