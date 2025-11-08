import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/asset_link_parser.dart';

/// Extract asset links from story content.
///
/// Extracts image embeds (storypad://assets/) and audio embeds (storypad://audio/).
///
/// Example:
/// ```dart
/// // Input: Content with pages containing image and audio embeds
/// // {
/// //   "insert": {"image": "storypad://assets/1762500783746"}
/// // },
/// // {
/// //   "insert": {"audio": "storypad://audio/1762500783747"}
/// // }
///
/// // Output:
/// final images = StoryExtractAssetsFromContentService.images(content);
/// // ["storypad://assets/1762500783746"]
///
/// final audios = StoryExtractAssetsFromContentService.audio(content);
/// // ["storypad://audio/1762500783747"]
/// ```
class StoryExtractAssetsFromContentService {
  static List<String> images(StoryContentDbModel? content) => _extractByEmbedLinkPrefix(
    content,
    AssetType.image.embedLinkPrefix,
  );

  static List<String> audio(StoryContentDbModel? content) => _extractByEmbedLinkPrefix(
    content,
    AssetType.audio.embedLinkPrefix,
  );

  static List<String> all(StoryContentDbModel? content) => [
    ...images(content),
    ...audio(content),
  ];

  static List<String> _extractByEmbedLinkPrefix(StoryContentDbModel? content, String scheme) {
    final links = <String>[];
    final pages = content?.richPages ?? [];

    for (final page in pages) {
      if (page.body == null || page.body!.isEmpty) continue;
      links.addAll(AssetLinkParser.extractByEmbedLinkPrefix(page.body, scheme));
    }

    return links;
  }
}
