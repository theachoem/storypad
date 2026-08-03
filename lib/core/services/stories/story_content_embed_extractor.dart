import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/assets/asset_link_parser.dart';
import 'package:storypad/core/types/asset_type.dart';

/// Extract embed sources from story content.
///
/// Example:
/// ```dart
/// // Input: Content with pages containing image and audio embeds
/// // {
/// //   "insert": {"image": "images/1762500783746.jpg"}
/// // },
/// // {
/// //   "insert": {"audio": "audio/1762500783747.m4a"}
/// // }
///
/// // Output:
/// final images = StoryContentEmbedExtractor.images(content);
/// // ["images/1762500783746.jpg"]
///
/// final audios = StoryContentEmbedExtractor.audio(content);
/// // ["audio/1762500783747.m4a"]
/// ```
class StoryContentEmbedExtractor {
  /// All **visual media** — photos *and* videos. Video reuses the `image` embed
  /// key (see docs/app/features/media.md), so this is deliberately the union,
  /// which is what viewers and story tiles want. Use [photos]/[videos] when you
  /// mean one kind specifically (counts, labels, filters).
  static List<String> images(StoryContentDbModel? content) => _extractEmbedSources(content, 'image');

  static List<String> audio(StoryContentDbModel? content) => _extractEmbedSources(content, 'audio');

  /// Photos only — [images] minus anything stored under `videos/`.
  static List<String> photos(StoryContentDbModel? content) =>
      images(content).where((link) => AssetType.getTypeFromLink(link) != AssetType.video).toList();

  /// Videos only — the complement of [photos] within [images].
  static List<String> videos(StoryContentDbModel? content) =>
      images(content).where((link) => AssetType.getTypeFromLink(link) == AssetType.video).toList();

  static List<String> all(StoryContentDbModel? content) => [
    ...photos(content),
    ...videos(content),
    ...audio(content),
  ];

  /// All asset ids referenced anywhere in the content (any embed type),
  /// e.g. to bulk-preload their aspect ratios before rendering (see
  /// `AssetsBox.preloadAspectRatios`).
  static Set<int> assetIds(StoryContentDbModel? content) {
    final ids = <int>{};
    for (final page in content?.richPages ?? []) {
      if (page.body == null || page.body!.isEmpty) continue;
      ids.addAll(AssetLinkParser.extractIds(page.body));
    }
    return ids;
  }

  /// Bulk-warms the aspect-ratio cache for every asset referenced by
  /// [loadedStories] in one native call, so story tiles don't each do their own
  /// `box.get` during scroll/build.
  ///
  /// Every list that renders story tiles calls this right after a batch loads
  /// (`HomeViewModel.setStories`, `SpStoryListWithQuery`) -- it lives here so
  /// they can't drift apart as embed parsing or the cache API change.
  static void preloadAssetAspectRatios(List<StoryDbModel> loadedStories) {
    final ids = <int>{};
    for (final story in loadedStories) {
      ids.addAll(assetIds(story.draftContent ?? story.latestContent));
    }
    AssetDbModel.db.preloadAspectRatios(ids);
  }

  static List<String> _extractEmbedSources(StoryContentDbModel? content, String embedType) {
    final links = <String>[];
    final pages = content?.richPages ?? [];

    for (final page in pages) {
      if (page.body == null || page.body!.isEmpty) continue;
      links.addAll(AssetLinkParser.extractEmbedSources(page.body, embedType));
    }

    return links;
  }
}
