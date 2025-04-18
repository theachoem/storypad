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

  RelaxSoundObject({
    required this.translationKey,
    required this.svgIconPath,
    required this.soundPath,
  });

  String get label => tr(translationKey);
  String get svgIconUrl => baseUrl + svgIconPath;
  String get soundUrl => baseUrl + soundPath;

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
        svgIconPath: '/assets/relax_sounds/rainy/light_rain.svg',
        soundPath: '/assets/relax_sounds/rainy/light_rain.wav',
      ),
      RelaxSoundObject(
        translationKey: 'sounds.rain_on_window',
        svgIconPath: '/assets/relax_sounds/rainy/rain_on_window.svg',
        soundPath: '/assets/relax_sounds/rainy/rain_on_window.wav',
      ),
      RelaxSoundObject(
        translationKey: 'sounds.heavy_rain',
        svgIconPath: '/assets/relax_sounds/rainy/heavy_rain.svg',
        soundPath: '/assets/relax_sounds/rainy/heavy_rain.wav',
      ),
      RelaxSoundObject(
        translationKey: 'sounds.thunder',
        svgIconPath: '/assets/relax_sounds/rainy/thunder.svg',
        soundPath: '/assets/relax_sounds/rainy/thunder.wav',
      ),
    ];
  }

  static List<RelaxSoundObject> waterSounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.ocean_waves',
        svgIconPath: '/assets/relax_sounds/water/ocean_waves.svg',
        soundPath: '/assets/relax_sounds/water/ocean_waves.wav',
      ),
      RelaxSoundObject(
        translationKey: 'sounds.river_stream',
        svgIconPath: '/assets/relax_sounds/water/river_stream.svg',
        soundPath: '/assets/relax_sounds/water/river_stream.wav',
      ),
      RelaxSoundObject(
        translationKey: 'sounds.droplets',
        svgIconPath: '/assets/relax_sounds/water/droplets.svg',
        soundPath: '/assets/relax_sounds/water/droplets.wav',
      ),
    ];
  }

  static List<RelaxSoundObject> animalSounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.night_crickets',
        svgIconPath: '/assets/relax_sounds/animal/night_crickets.svg',
        soundPath: '/assets/relax_sounds/animal/night_crickets.wav',
      ),
      RelaxSoundObject(
        translationKey: 'sounds.frogs',
        svgIconPath: '/assets/relax_sounds/animal/frogs.svg',
        soundPath: '/assets/relax_sounds/animal/frogs.wav',
      ),
      RelaxSoundObject(
        translationKey: 'sounds.forest_birds',
        svgIconPath: '/assets/relax_sounds/animal/forest_birds.svg',
        soundPath: '/assets/relax_sounds/animal/forest_birds.wav',
      ),
    ];
  }

  Map<String, dynamic> toJson() => _$RelaxSoundObjectToJson(this);
  factory RelaxSoundObject.fromJson(Map<String, dynamic> json) => _$RelaxSoundObjectFromJson(json);
}
