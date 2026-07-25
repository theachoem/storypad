import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/assets/asset_link_parser.dart';

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
  static List<String> images(StoryContentDbModel? content) => _extractEmbedSources(content, 'image');
  static List<String> audio(StoryContentDbModel? content) => _extractEmbedSources(content, 'audio');

  static List<String> all(StoryContentDbModel? content) => [
    ...images(content),
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
