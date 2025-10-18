import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/types/firestore_storage_background.dart';

part 'relax_sound_object.g.dart';

@CopyWith()
@JsonSerializable()
class RelaxSoundObject {
  final String translationKey;
  final String artist;
  final String svgIconUrlPath;
  final FirestoreStorageBackground background;

  // mp3 or wave
  final String soundUrlPath;

  // Base on Cambodia tranditional color by weekday (1 to 7)
  final int dayColor;

  RelaxSoundObject({
    required this.artist,
    required this.translationKey,
    required this.svgIconUrlPath,
    required this.background,
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
      ...activitySounds(),
      ...musicSounds(),
    ];
  }

  static List<RelaxSoundObject> rainySounds() {
    return [
      RelaxSoundObject(
        artist: '@jmbphilmes',
        translationKey: 'sounds.light_rain',
        background: FirestoreStorageBackground.textured_green_and_black_liquefy_abstract_background,
        svgIconUrlPath: '/relax_sounds/rainy/light_rain.svg',
        soundUrlPath: '/relax_sounds/rainy/light_rain.wav',
        dayColor: 3,
      ),
      RelaxSoundObject(
        artist: '@InspectorJ',
        translationKey: 'sounds.rain_on_window',
        background: FirestoreStorageBackground.textured_green_and_black_liquefy_abstract_background,
        svgIconUrlPath: '/relax_sounds/rainy/rain_on_window.svg',
        soundUrlPath: '/relax_sounds/rainy/rain_on_window.wav',
        dayColor: 4,
      ),
      RelaxSoundObject(
        artist: '@lebaston100',
        translationKey: 'sounds.heavy_rain',
        background: FirestoreStorageBackground.textured_green_and_black_liquefy_abstract_background,
        svgIconUrlPath: '/relax_sounds/rainy/heavy_rain.svg',
        soundUrlPath: '/relax_sounds/rainy/heavy_rain.wav',
        dayColor: 6,
      ),
      RelaxSoundObject(
        artist: '@laribum',
        translationKey: 'sounds.thunder',
        background: FirestoreStorageBackground.textured_green_and_black_liquefy_abstract_background,
        svgIconUrlPath: '/relax_sounds/rainy/thunder.svg',
        soundUrlPath: '/relax_sounds/rainy/thunder.wav',
        dayColor: 6,
      ),
    ];
  }

  static List<RelaxSoundObject> waterSounds() {
    return [
      RelaxSoundObject(
        artist: '@Profispiesser',
        translationKey: 'sounds.ocean_waves',
        background: FirestoreStorageBackground.abstract_water_drops_on_turquoise_glass_background,
        svgIconUrlPath: '/relax_sounds/water/ocean_waves.svg',
        soundUrlPath: '/relax_sounds/water/ocean_waves.wav',
        dayColor: 5,
      ),
      RelaxSoundObject(
        artist: '@felix.blume',
        translationKey: 'sounds.river_stream',
        background: FirestoreStorageBackground.abstract_water_drops_on_turquoise_glass_background,
        svgIconUrlPath: '/relax_sounds/water/river_stream.svg',
        soundUrlPath: '/relax_sounds/water/river_stream.wav',
        dayColor: 5,
      ),
      RelaxSoundObject(
        artist: '@Lydmakeren',
        translationKey: 'sounds.droplets',
        background: FirestoreStorageBackground.abstract_water_drops_on_turquoise_glass_background,
        svgIconUrlPath: '/relax_sounds/water/droplets.svg',
        soundUrlPath: '/relax_sounds/water/droplets.wav',
        dayColor: 5,
      ),
      RelaxSoundObject(
        artist: '@brunoboselli',
        translationKey: 'sounds.bubbles',
        background: FirestoreStorageBackground.abstract_water_drops_on_turquoise_glass_background,
        svgIconUrlPath: '/relax_sounds/water/bubbles.svg',
        soundUrlPath: '/relax_sounds/water/bubbles.wav',
        dayColor: 5,
      ),
    ];
  }

  static List<RelaxSoundObject> animalSounds() {
    return [
      RelaxSoundObject(
        artist: '@Virgile_Loiseau',
        translationKey: 'sounds.night_crickets',
        background: FirestoreStorageBackground.forest_full_of_high_rise_trees,
        svgIconUrlPath: '/relax_sounds/animal/night_crickets.svg',
        soundUrlPath: '/relax_sounds/animal/night_crickets.wav',
        dayColor: 2,
      ),
      RelaxSoundObject(
        artist: '@sacred_steel',
        translationKey: 'sounds.cicada',
        background: FirestoreStorageBackground.forest_full_of_high_rise_trees,
        svgIconUrlPath: '/relax_sounds/animal/cicada.svg',
        soundUrlPath: '/relax_sounds/animal/cicada.wav',
        dayColor: 4,
      ),
      RelaxSoundObject(
        artist: '@eyecandyuk',
        translationKey: 'sounds.frogs',
        background: FirestoreStorageBackground.forest_full_of_high_rise_trees,
        svgIconUrlPath: '/relax_sounds/animal/frogs.svg',
        soundUrlPath: '/relax_sounds/animal/frogs.wav',
        dayColor: 1,
      ),
      RelaxSoundObject(
        artist: '@reinsamba',
        translationKey: 'sounds.forest_birds',
        background: FirestoreStorageBackground.fall_leaves_hanging_on_blurry_surface,
        svgIconUrlPath: '/relax_sounds/animal/forest_birds.svg',
        soundUrlPath: '/relax_sounds/animal/forest_birds.wav',
        dayColor: 3,
      ),
      RelaxSoundObject(
        artist: '@interstellar_galleon',
        translationKey: 'sounds.seagulls',
        background: FirestoreStorageBackground.fall_leaves_hanging_on_blurry_surface,
        svgIconUrlPath: '/relax_sounds/animal/seagulls.svg',
        soundUrlPath: '/relax_sounds/animal/seagulls.wav',
        dayColor: 5,
      ),
    ];
  }

  static List<RelaxSoundObject> melodySounds() {
    return [
      RelaxSoundObject(
        artist: '@AnoukJade',
        translationKey: 'sounds.wind_chime',
        background: FirestoreStorageBackground.color_beautiful_sky_vintage_forest,
        svgIconUrlPath: '/relax_sounds/melody/wind_chime.svg',
        soundUrlPath: '/relax_sounds/melody/wind_chime.wav',
        dayColor: 5,
      ),
      RelaxSoundObject(
        artist: '@LoopUdu',
        translationKey: 'sounds.bamboo_windchime',
        background: FirestoreStorageBackground.color_beautiful_sky_vintage_forest,
        svgIconUrlPath: '/relax_sounds/melody/bamboo_windchime.svg',
        soundUrlPath: '/relax_sounds/melody/bamboo_windchime.wav',
        dayColor: 5,
      ),
      RelaxSoundObject(
        artist: '@imagefilm.berlin',
        translationKey: 'sounds.singing_bowl',
        background: FirestoreStorageBackground.color_beautiful_sky_vintage_forest,
        svgIconUrlPath: '/relax_sounds/melody/singing_bowl.svg',
        soundUrlPath: '/relax_sounds/melody/singing_bowl.wav',
        dayColor: 1,
      ),
      RelaxSoundObject(
        artist: 'mhuxley@marianst.com.au',
        translationKey: 'sounds.ticking_clock',
        background: FirestoreStorageBackground.music_notes_on_heart_shaped_paper,
        svgIconUrlPath: '/relax_sounds/melody/ticking_clock.svg',
        soundUrlPath: '/relax_sounds/melody/ticking_clock.wav',
        dayColor: 5,
      ),
    ];
  }

  static List<RelaxSoundObject> fireSounds() {
    return [
      RelaxSoundObject(
        artist: '@StevenMyat_',
        translationKey: 'sounds.campfire',
        background: FirestoreStorageBackground.cups_and_pot_near_fire,
        svgIconUrlPath: '/relax_sounds/fire/campfire.svg',
        soundUrlPath: '/relax_sounds/fire/campfire.wav',
        dayColor: 1,
      ),
      RelaxSoundObject(
        artist: '@eclectic-kitty',
        translationKey: 'sounds.sausage_frying',
        background: FirestoreStorageBackground.cups_and_pot_near_fire,
        svgIconUrlPath: '/relax_sounds/fire/sausage_frying.svg',
        soundUrlPath: '/relax_sounds/fire/sausage_frying.wav',
        dayColor: 7,
      ),
    ];
  }

  static List<RelaxSoundObject> bodySounds() {
    return [
      RelaxSoundObject(
        artist: '@RICHERlandTV',
        translationKey: 'sounds.heartbeat',
        background: FirestoreStorageBackground.two_cloudy_tags_on_color_background,
        svgIconUrlPath: '/relax_sounds/body/heartbeat.svg',
        soundUrlPath: '/relax_sounds/body/heartbeat.wav',
        dayColor: 7,
      ),
    ];
  }

  static List<RelaxSoundObject> activitySounds() {
    return [
      RelaxSoundObject(
        artist: '@forfii',
        translationKey: 'sounds.typing',
        background: FirestoreStorageBackground.designer_at_work_in_office,
        svgIconUrlPath: '/relax_sounds/activity/typing.svg',
        soundUrlPath: '/relax_sounds/activity/typing.wav',
        dayColor: 7,
      ),
    ];
  }

  static List<RelaxSoundObject> musicSounds() {
    return [
      RelaxSoundObject(
        artist: '@voyouz',
        translationKey: 'sounds.music_box',
        background: FirestoreStorageBackground.music_notes_on_heart_shaped_paper,
        svgIconUrlPath: '/relax_sounds/musics/music_box.svg',
        soundUrlPath: '/relax_sounds/musics/music_box.wav',
        dayColor: 1,
      ),
      RelaxSoundObject(
        artist: '@graham_makes',
        translationKey: 'sounds.acoustic_guitar_duet',
        background: FirestoreStorageBackground.music_notes_on_heart_shaped_paper,
        svgIconUrlPath: '/relax_sounds/musics/acoustic_guitar_duet.svg',
        soundUrlPath: '/relax_sounds/musics/acoustic_guitar_duet.mp3',
        dayColor: 3,
      ),

      RelaxSoundObject(
        artist: '@Matio888',
        translationKey: 'sounds.serene_piano_reflections',
        background: FirestoreStorageBackground.two_cloudy_tags_on_color_background,
        svgIconUrlPath: '/relax_sounds/musics/serene_piano_reflections.svg',
        soundUrlPath: '/relax_sounds/musics/serene_piano_reflections.mp3',
        dayColor: 2,
      ),
      RelaxSoundObject(
        artist: '@Gustavo_Alivera',
        translationKey: 'sounds.serene_moments',
        background: FirestoreStorageBackground.color_beautiful_sky_vintage_forest,
        svgIconUrlPath: '/relax_sounds/musics/serene_moments.svg',
        soundUrlPath: '/relax_sounds/musics/serene_moments.mp3',
        dayColor: 1,
      ),
    ];
  }

  Map<String, dynamic> toJson() => _$RelaxSoundObjectToJson(this);
  factory RelaxSoundObject.fromJson(Map<String, dynamic> json) => _$RelaxSoundObjectFromJson(json);
}
