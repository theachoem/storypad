import 'package:storypad/core/types/asset_type.dart';

/// Parse asset links and IDs from Quill Delta format.
///
/// Quill Delta represents content as a list of operations with structure:
/// ```
/// [
///   { "insert": "Hello " },
///   { "insert": { "image": "storypad://assets/123" } },
///   { "insert": { "audio": "storypad://audio/456" } }
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
  ///   { "insert": { "image": "storypad://assets/123" } },
  ///   { "insert": { "audio": "storypad://audio/456" } }
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
          final assetId = AssetType.parseAssetId(value);
          if (assetId != null) ids.add(assetId);
        }
      }
    }

    return ids;
  }

  /// Extract asset links (as strings) by prefix
  ///
  /// Returns a List of asset links that start with the given prefix.
  /// This is useful when you need the full links rather than just IDs.
  ///
  /// Example:
  /// ```dart
  /// final audioLinks = AssetLinkParser.extractByEmbedLinkPrefix(
  ///   body,
  ///   AssetType.audio.embedLinkPrefix
  /// );
  /// // audioLinks == ['storypad://audio/456']
  /// ```
  static List<String> extractByEmbedLinkPrefix(List<dynamic>? body, String scheme) {
    final links = <String>[];
    if (body == null || body.isEmpty) return links;

    for (final node in body) {
      if (node is! Map || node['insert'] is! Map) continue;

      final insert = node['insert'] as Map;
      for (final value in insert.values) {
        if (value is String && value.startsWith(scheme)) {
          links.add(value);
        }
      }
    }

    return links;
  }
}
