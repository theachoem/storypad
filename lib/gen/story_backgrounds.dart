// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  Story Backgrounds Generator
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint

enum StoryBackgroundAlign {
  left,
  center,
  right,
}

enum StoryBackgroundTextColor {
  black,
  white,
}

class StoryBackground {
  final String name;
  final String path;
  final StoryBackgroundAlign align;
  final StoryBackgroundTextColor textColor;

  const StoryBackground({
    required this.name,
    required this.path,
    required this.align,
    required this.textColor,
  });
}

class StoryBackgrounds {
  const StoryBackgrounds._();

  static const photorealistic = [
    StoryBackground(
      name:
          'beautiful-girl-enjoying-flowers-fields-sunrise-viewpoint-tak-province-1',
      path:
          '/story_backgrounds/photorealistic__beautiful-girl-enjoying-flowers-fields-sunrise-viewpoint-tak-province-1__align-right__text-white.jpg',
      align: .right,
      textColor: .white,
    ),
    StoryBackground(
      name: 'watercolor-winter-landscape',
      path:
          '/story_backgrounds/photorealistic__watercolor-winter-landscape__align-right__text-black.jpg',
      align: .right,
      textColor: .black,
    ),
    StoryBackground(
      name: 'christmas-celebration-with-decorated-house-1',
      path:
          '/story_backgrounds/photorealistic__christmas-celebration-with-decorated-house-1__align-left__text-white.jpg',
      align: .left,
      textColor: .white,
    ),
    StoryBackground(
      name: 'mountain-grassland-environmental-ecology-park-nature-concept-1',
      path:
          '/story_backgrounds/photorealistic__mountain-grassland-environmental-ecology-park-nature-concept-1__align-right__text-white.jpg',
      align: .right,
      textColor: .white,
    ),
    StoryBackground(
      name: 'beach-sunset-with-clouds-1',
      path:
          '/story_backgrounds/photorealistic__beach-sunset-with-clouds-1__align-center__text-white.jpg',
      align: .center,
      textColor: .white,
    ),
  ];

  static const scene = [
    StoryBackground(
      name:
          'nature-scene-rural-land-agriculture-grassland-abtract-silhouette-asian-farmers-working-rice-field-il',
      path:
          '/story_backgrounds/scene__nature-scene-rural-land-agriculture-grassland-abtract-silhouette-asian-farmers-working-rice-field-il__align-left__text_white.jpg',
      align: .left,
      textColor: .white,
    ),
  ];

  static const all = <String, List<StoryBackground>>{
    'photorealistic': photorealistic,
    'scene': scene,
  };

  static final byFilename = <String, StoryBackground>{
    'photorealistic__beautiful-girl-enjoying-flowers-fields-sunrise-viewpoint-tak-province-1__align-right__text-white.jpg':
        photorealistic[0],
    'photorealistic__watercolor-winter-landscape__align-right__text-black.jpg':
        photorealistic[1],
    'photorealistic__christmas-celebration-with-decorated-house-1__align-left__text-white.jpg':
        photorealistic[2],
    'photorealistic__mountain-grassland-environmental-ecology-park-nature-concept-1__align-right__text-white.jpg':
        photorealistic[3],
    'photorealistic__beach-sunset-with-clouds-1__align-center__text-white.jpg':
        photorealistic[4],
    'scene__nature-scene-rural-land-agriculture-grassland-abtract-silhouette-asian-farmers-working-rice-field-il__align-left__text_white.jpg':
        scene[0],
  };

  static const groups = [
    'photorealistic',
    'scene',
  ];
}
