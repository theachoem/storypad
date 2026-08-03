import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/support_directory_path.dart';
import 'package:storypad/widgets/sp_icons.dart';

/// Asset type enumeration with storage subdirectory management.
///
/// This is the single source of truth for asset types and how they are
/// stored in the application. Adding new asset types requires
/// adding a new enum value only.
///
/// Example relative paths:
/// - Image: images/1762500783746.jpg
/// - Audio: audio/1762500783747.m4a
/// - Video: videos/1762500783748.mp4
enum AssetType {
  /// Image asset type (photos, screenshots, etc.)
  ///
  /// Stores files in the 'images' subdirectory.
  /// Example: images/1762500783746.jpg
  image(subDirectory: .images),

  /// Audio asset type (voice notes, recordings, etc.)
  ///
  /// Stores files in the 'audio' subdirectory.
  /// Example: audio/1762500783747.m4a
  audio(subDirectory: .audio),

  /// Video asset type (recorded/picked videos)
  ///
  /// Stores files in the 'videos' subdirectory.
  /// Example: videos/1762500783748.mp4
  video(subDirectory: .videos);

  final SupportDirectoryPath subDirectory;

  const AssetType({
    required this.subDirectory,
  });

  /// Icon representing this asset type, so call sites don't branch on the type
  /// themselves (media stats rows, import review tabs, ...).
  IconData get icon {
    switch (this) {
      case AssetType.image:
        return SpIcons.photo;
      case AssetType.audio:
        return SpIcons.voice;
      case AssetType.video:
        return SpIcons.videoCamera;
    }
  }

  /// Localized plural label for this asset type ("Photos", "Voices", "Videos").
  String get label {
    switch (this) {
      case AssetType.image:
        return tr('general.photos');
      case AssetType.audio:
        return tr('general.voices');
      case AssetType.video:
        return tr('general.videos');
    }
  }

  String getStoragePath({
    required int id,
    required String extension,
  }) {
    /// Get the storage path for an asset based on ID, extension, and type.
    /// This is the single source of truth for path construction.
    return "${subDirectory.directoryPath}/$id$extension";
  }

  String getRelativeStoragePath({
    required int id,
    required String extension,
  }) {
    /// Get the relative storage path for an asset based on ID, extension, and type.
    /// This is used for storing paths in the database.
    return "${subDirectory.relativePath}/$id$extension";
  }

  static AssetType fromValue(String? value) {
    for (var type in AssetType.values) {
      if (type.name == value) return type;
    }
    return AssetType.image;
  }

  /// Parse asset ID from a relative file path
  ///
  /// Extracts the numeric ID from paths like:
  /// - images/1762500783746.jpg → 1762500783746
  /// - audio/1762500783747.m4a → 1762500783747
  static int? parseAssetId(String relativePath) {
    final assetId = relativePath.split("/").last.split(".").first;
    final assetIdInt = int.tryParse(assetId);
    return assetIdInt;
  }

  /// Determine asset type from a relative file path
  ///
  /// Returns the asset type enum based on the subdirectory prefix.
  /// Returns null if the path doesn't match any known type.
  static AssetType? getTypeFromLink(String relativePath) {
    for (final type in AssetType.values) {
      if (relativePath.startsWith(type.subDirectory.relativePath)) return type;
    }
    return null;
  }
}
