import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/asset_link_parser.dart';

/// Extract all asset IDs from story pages.
///
/// Automatically discovers assets from any embed type
/// (image, audio, video, file, etc.)
///
/// Example:
/// ```dart
/// // Input: Page with image and audio embeds
/// // {
/// //   "insert": {"image": "storypad://assets/1762500783746"}
/// // },
/// // {
/// //   "insert": {"audio": "storypad://audio/1762500783747"}
/// // }
///
/// // Output: {1762500783746, 1762500783747}
/// final ids = StoryExtractAssetsFromPagesService.call(pages);
/// ```
class StoryExtractAssetsFromPagesService {
  static Set<int> call(List<StoryPageDbModel>? pages) {
    final assets = <int>{};
    if (pages == null || pages.isEmpty) return assets;

    for (final page in pages) {
      assets.addAll(AssetLinkParser.extractIds(page.body));
    }

    return assets;
  }
}
