import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/adapters/objectbox/assets_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';

part 'asset_db_model.g.dart';

String _assetTypeToJson(AssetType type) => type.name;
AssetType _assetTypeFromJson(String json) => AssetType.fromValue(json);

@CopyWith()
@JsonSerializable()
class AssetDbModel extends BaseDbModel {
  static const String cloudId = "google_drive";

  // ignore: constant_identifier_names
  static const String DURATION_KEY = "duration_in_ms";

  static final AssetsBox db = AssetsBox();

  @override
  final int id;
  final String originalSource;
  final Map<String, Map<String, Map<String, String>>> cloudDestinations;

  @JsonKey(fromJson: _assetTypeFromJson, toJson: _assetTypeToJson)
  final AssetType type;

  // Flexible metadata storage (duration, transcription, etc.)
  final Map<String, dynamic>? metadata;

  final DateTime createdAt;

  @override
  final DateTime updatedAt;
  final String? lastSavedDeviceId;

  @override
  final DateTime? permanentlyDeletedAt;

  AssetDbModel({
    required this.id,
    required this.originalSource,
    required this.cloudDestinations,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSavedDeviceId,
    required this.permanentlyDeletedAt,
    required this.type,
    this.metadata,
  });

  bool get needBackup => !originalSource.startsWith("http") && cloudDestinations.isEmpty;

  String? get cloudFileName => localFile != null ? "$id${extension(localFile!.path)}" : null;

  /// URI link for embedding in Quill editor
  ///
  /// Automatically routes to correct scheme based on asset type:
  /// - Audio: storypad://audio/{id}
  /// - Image (or null): storypad://assets/{id}
  String get link => type.buildEmbedLink(id);

  bool get isAudio => type == AssetType.audio;
  bool get isImage => type == AssetType.image;
  int? get durationInMs => (metadata?[DURATION_KEY] is int) ? metadata![DURATION_KEY] as int : null;

  /// Format duration to readable string (MM:SS)
  String? get formattedDuration {
    final duration = durationInMs;
    if (duration == null) return null;

    final seconds = (duration ~/ 1000) % 60;
    final minutes = (duration ~/ (1000 * 60)) % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  File? get localFile {
    final file = File(originalSource);
    if (file.existsSync()) return file;

    final possibleFile = File(downloadFilePath);
    if (possibleFile.existsSync()) return possibleFile;

    return null;
  }

  /// Get the storage path for this asset.
  ///
  /// Example output:
  /// - Image: `/support/dir/images/1762500783746.jpg`
  /// - Audio: `/support/dir/audio/1762500783746.m4a`
  String get downloadFilePath {
    return type.getStoragePath(
      id: id,
      extension: extension(originalSource),
    );
  }

  factory AssetDbModel.fromLocalPath({
    required int id,
    required String localPath,
    required AssetType type,
    int? durationInMs,
  }) {
    final now = DateTime.now();

    Map<String, dynamic>? metadata;
    if (durationInMs != null) {
      metadata = {DURATION_KEY: durationInMs};
    }

    return AssetDbModel(
      id: id,
      originalSource: localPath,
      cloudDestinations: {},
      createdAt: now,
      updatedAt: now,
      permanentlyDeletedAt: null,
      lastSavedDeviceId: null,
      type: type,
      metadata: metadata,
    );
  }

  /// Create a copy with updated duration metadata
  AssetDbModel copyWithDuration(int durationInMs) {
    final newMetadata = {...(metadata ?? {})};
    newMetadata[DURATION_KEY] = durationInMs;

    return copyWith(
      metadata: newMetadata,
      updatedAt: DateTime.now(),
    );
  }

  bool isGoogleDriveUploadedFor(String? email) {
    return getGoogleDriveIdForEmail(email ?? '') != null;
  }

  List<String>? getGoogleDriveForEmails() {
    return cloudDestinations[cloudId]?.keys.toList();
  }

  String? getGoogleDriveUrlForEmail(String email) {
    final fileId = getGoogleDriveIdForEmail(email);
    if (fileId is String) {
      return "https://www.googleapis.com/drive/v3/files/$fileId?alt=media";
    }
    return null;
  }

  String? getGoogleDriveIdForEmail(String email) {
    return cloudDestinations[cloudId]?[email]?['file_id'];
  }

  Future<AssetDbModel?> save() async => db.set(this);
  Future<void> delete() async => db.delete(id);

  /// Find an asset by its URI link
  ///
  /// Supports both image and audio schemes:
  /// - storypad://assets/{id}
  /// - storypad://audio/{id}
  static Future<AssetDbModel?> findBy({
    required String assetLink,
  }) async {
    final id = AssetType.parseAssetId(assetLink);
    return id != null ? AssetDbModel.db.find(id) : null;
  }

  AssetDbModel copyWithGoogleDriveCloudFile({
    required CloudFileObject cloudFile,
    required String email,
  }) {
    Map<String, Map<String, Map<String, String>>> newCloudDestinations = {...cloudDestinations};

    newCloudDestinations[cloudId] ??= {};
    newCloudDestinations[cloudId]![email] = {
      'file_id': cloudFile.id,
      'file_name': cloudFile.fileName!,
    };

    return copyWith(
      cloudDestinations: newCloudDestinations,
      updatedAt: DateTime.now(),
    );
  }

  factory AssetDbModel.fromJson(Map<String, dynamic> json) => _$AssetDbModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AssetDbModelToJson(this);

  bool _cloudViewing = false;
  bool get cloudViewing => _cloudViewing;
  AssetDbModel markAsCloudViewing() {
    _cloudViewing = true;
    return this;
  }
}
