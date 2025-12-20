/// Parse asset paths and IDs from Quill Delta format.
///
/// Quill Delta represents content as a list of operations with structure:
/// ```
/// [
///   { "insert": "Hello " },
///   { "insert": { "image": "images/123.jpg" } },
///   { "insert": { "audio": "audio/456.m4a" } }
/// ]
/// ```
///
/// This class provides utilities to extract asset references from this format.
class AssetLinkParser {
  /// Extract all asset IDs from Quill Delta body
  ///
  /// Returns a Set of unique asset IDs found in the body.
  /// Supports all asset types (images, audio, future types).
  ///
  /// Example:
  /// ```dart
  /// final body = [
  ///   { "insert": { "image": "assets/123.jpg" } },
  ///   { "insert": { "audio": "audio/456.m4a" } }
  /// ];
  /// final ids = AssetLinkParser.extractIds(body);
  /// // ids == {123, 456}
  /// ```
  static Set<int> extractIds(List<dynamic>? body) {
    final ids = <int>{};
    if (body == null || body.isEmpty) return ids;

    for (final node in body) {
      if (node is! Map || node['insert'] is! Map) continue;

      final insert = node['insert'] as Map;
      for (final value in insert.values) {
        if (value is String) {
          final assetId = value.split("/").last.split(".").first;
          final assetIdInt = int.tryParse(assetId);
          if (assetIdInt != null) ids.add(assetIdInt);
        }
      }
    }

    return ids;
  }

  /// Extract embed sources of a specific embed type from Quill Delta body.
  ///
  /// This method scans the provided Quill Delta body for nodes that contain
  /// the specified embed type and returns a list of corresponding source values.
  /// Returns both local asset paths (images/, audio/) and external URLs (http://, https://),
  /// but filters out empty strings and other invalid values.
  ///
  /// Example:
  /// ```dart
  /// // Input: Content with pages containing image and audio embeds
  /// final body = [
  ///   {
  ///     "insert": {"image": "images/1762500783746.jpg"}  // local asset
  ///   },
  ///   {
  ///     "insert": {"audio": "audio/1762500783747.m4a"}  // local asset
  ///   },
  ///   {
  ///     "insert": {"image": "https://example.com/image.jpg"}  // external URL
  ///   },
  ///   {
  ///     "insert": {"image": ""}  // filtered out
  ///   }
  /// ];
  ///
  /// final imageSources = AssetLinkParser.extractEmbedSources(
  ///   body,
  ///   'image',
  /// );
  /// // imageSources == ['images/1762500783746.jpg', 'https://example.com/image.jpg']
  /// ```
  static List<String> extractEmbedSources(List<dynamic>? body, String embedType) {
    final links = <String>[];
    if (body == null || body.isEmpty) return links;

    for (final node in body) {
      if (node is! Map || node['insert'] is! Map) continue;

      final insert = node['insert'] as Map;
      if (insert[embedType] is String) {
        final path = insert[embedType] as String;
        // Include: local asset paths (images/, audio/) or external URLs (http://, https://)
        // Exclude: empty strings and other invalid values
        if (path.isNotEmpty) {
          links.add(path);
        }
      }
    }

    return links;
  }
}
