import 'package:storypad/core/constants/app_constants.dart';

/// Asset type enumeration with URI scheme management.
///
/// This is the single source of truth for asset types and how they are
/// referenced throughout the application. Adding new asset types requires
/// adding a new enum value only.
///
/// Example asset links:
/// - Image: storypad://assets/1762500783746
/// - Audio: storypad://audio/1762500783747
enum AssetType {
  /// Original asset type.
  ///
  /// Uses 'assets' in the URI for backward compatibility with existing
  /// embed links, but stores files in the 'images' subdirectory.
  /// This naming mismatch is intentional to maintain compatibility.
  image(embedLinkPath: 'assets', subDirectory: 'images'),

  /// Recently added asset type for audio files (voice notes, etc.).
  ///
  /// Uses 'audio' for both URI scheme and storage subdirectory.
  audio(embedLinkPath: 'audio', subDirectory: 'audio');

  final String embedLinkPath;
  final String subDirectory;

  const AssetType({
    required this.embedLinkPath,
    required this.subDirectory,
  });

  /// Full URI path for this asset type
  /// Returns: "storypad://{path}/"
  String get embedLinkPrefix => 'storypad://$embedLinkPath/';

  /// Build a complete link for the given asset ID
  /// Returns: "storypad://{scheme}/{id}"
  String buildEmbedLink(int id) => '$embedLinkPrefix$id';

  String getStoragePath({
    required int id,
    required String extension,
  }) {
    /// Get the storage path for an asset based on ID, extension, and type.
    /// This is the single source of truth for path construction.
    return "${kSupportDirectory.path}/$subDirectory/$id$extension";
  }

  static AssetType fromValue(String? value) {
    for (var type in AssetType.values) {
      if (type.name == value) return type;
    }
    return AssetType.image;
  }

  /// Parse asset ID from a URI link
  ///
  /// Returns null if the link doesn't match this type's scheme.
  ///
  /// Example:
  /// ```dart
  /// final id = AssetType.audio.parseAssetIdFromLink('storypad://audio/123');
  /// // id == 123
  /// ```
  int? parseAssetIdFromLink(String link) {
    if (link.startsWith(embedLinkPrefix)) {
      return int.tryParse(link.substring(embedLinkPrefix.length));
    }
    return null;
  }

  /// Parse asset ID from a URI link (convenience method)
  ///
  /// Tries to parse with any asset type and returns the ID if found.
  ///
  /// Example:
  /// ```dart
  /// final id = AssetType.parseAssetId('storypad://audio/123');
  /// // id == 123
  /// ```
  static int? parseAssetId(String link) {
    for (final type in AssetType.values) {
      if (link.startsWith(type.embedLinkPrefix)) {
        return int.tryParse(link.substring(type.embedLinkPrefix.length));
      }
    }
    return null;
  }

  /// Determine asset type from a URI link
  ///
  /// Returns the asset type enum or null if link is invalid.
  static AssetType? getTypeFromLink(String link) {
    for (final type in AssetType.values) {
      if (link.startsWith(type.embedLinkPrefix)) return type;
    }
    return null;
  }

  /// Check if a string is a valid asset link
  static bool isValidAssetLink(String link) {
    return AssetType.values.any((type) => link.startsWith(type.embedLinkPrefix));
  }

  /// All supported URI schemes (for validation and parsing)
  static List<String> get allEmbedLinkPrefixes => AssetType.values.map((t) => t.embedLinkPrefix).toList();
}
