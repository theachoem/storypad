import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';

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

  static Map<String, RelaxSoundObject>? _defaultSoundsList;
  static Map<String, RelaxSoundObject> defaultSoundsList() {
    if (_defaultSoundsList != null) return _defaultSoundsList!;

    for (var sound in defaultSounds()) {
      _defaultSoundsList ??= {};
      _defaultSoundsList?[sound.soundUrlPath] = sound;
    }

    return _defaultSoundsList!;
  }

  static List<RelaxSoundObject> defaultSounds() {
    return [
      ...rainySounds(),
      ...waterSounds(),
      ...animalSounds(),
      ...melodySounds(),
      ...fireSounds(),
      ...bodySounds(),
    ];
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
      RelaxSoundObject(
        translationKey: 'sounds.bubbles',
        svgIconUrlPath: '/relax_sounds/water/bubbles.svg',
        soundUrlPath: '/relax_sounds/water/bubbles.m4a',
        dayColor: 5,
      ),
    ];
  }

  static List<RelaxSoundObject> animalSounds() {
    return [
      // RelaxSoundObject(
      //   translationKey: 'sounds.night_crickets',
      //   svgIconUrlPath: '/relax_sounds/animal/night_crickets.svg',
      //   soundUrlPath: '/relax_sounds/animal/night_crickets.m4a',
      //   dayColor: 2,
      // ),
      RelaxSoundObject(
        translationKey: 'sounds.cicada',
        svgIconUrlPath: '/relax_sounds/animal/cicada.svg',
        soundUrlPath: '/relax_sounds/animal/cicada.m4a',
        dayColor: 4,
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
      RelaxSoundObject(
        translationKey: 'sounds.seagulls',
        svgIconUrlPath: '/relax_sounds/animal/seagulls.svg',
        soundUrlPath: '/relax_sounds/animal/seagulls.m4a',
        dayColor: 5,
      ),
    ];
  }

  static List<RelaxSoundObject> melodySounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.wind_chime',
        svgIconUrlPath: '/relax_sounds/melody/wind_chime.svg',
        soundUrlPath: '/relax_sounds/melody/wind_chime.m4a',
        dayColor: 5,
      ),
      RelaxSoundObject(
        translationKey: 'sounds.singing_bowl',
        svgIconUrlPath: '/relax_sounds/melody/singing_bowl.svg',
        soundUrlPath: '/relax_sounds/melody/singing_bowl.m4a',
        dayColor: 1,
      ),
    ];
  }

  static List<RelaxSoundObject> fireSounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.campfire',
        svgIconUrlPath: '/relax_sounds/fire/campfire.svg',
        soundUrlPath: '/relax_sounds/fire/campfire.m4a',
        dayColor: 1,
      ),
    ];
  }

  static List<RelaxSoundObject> bodySounds() {
    return [
      RelaxSoundObject(
        translationKey: 'sounds.heartbeat',
        svgIconUrlPath: '/relax_sounds/body/heartbeat.svg',
        soundUrlPath: '/relax_sounds/body/heartbeat.m4a',
        dayColor: 7,
      ),
    ];
  }

  Map<String, dynamic> toJson() => _$RelaxSoundObjectToJson(this);
  factory RelaxSoundObject.fromJson(Map<String, dynamic> json) => _$RelaxSoundObjectFromJson(json);
}
