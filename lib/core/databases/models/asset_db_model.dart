import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/adapters/objectbox/assets_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';

part 'asset_db_model.g.dart';

String _assetTypeToJson(AssetType type) => type.name;
AssetType _assetTypeFromJson(String? json) => AssetType.fromValue(json);

@CopyWith()
@JsonSerializable()
class AssetDbModel extends BaseDbModel {
  // ignore: constant_identifier_names
  static const String DURATION_KEY = "duration_in_ms";

  static final AssetsBox db = AssetsBox();

  @override
  final int id;

  // in v2, this is always a relative local file path
  // eg. "images/1762500783746.jpg"
  final String originalSource;

  final List<int>? tags;
  final int? version;

  // {
  //   "google_drive": {
  //     "user@example.com": {
  //       "file_id": "abc123xyz",
  //       "file_name": "1762500783746.jpg"
  //     },
  //     "another@example.com": {
  //       "file_id": "def456",
  //       "file_name": "1762500783746.jpg"
  //     }
  //   },
  //   "web_dav": {
  //     "storypad": {
  //       "file_id": "ghi789",
  //       "file_name": "1762500783746.jpg"
  //     }
  //   }
  // }
  final Map<String, Map<String, Map<String, String>>> cloudDestinations;

  @JsonKey(fromJson: _assetTypeFromJson, toJson: _assetTypeToJson)
  final AssetType type;

  // Flexible metadata storage (duration, transcription, etc.)
  final Map<String, dynamic>? metadata;

  // Original decoded dimensions of an image/video asset, captured once at
  // insert time -- lets tiles derive an aspect ratio without decoding metadata.
  final double? width;
  final double? height;

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
    required this.tags,
    this.version = 2,
    this.metadata,
    this.width,
    this.height,
  });

  bool get needBackup => !originalSource.startsWith("http") && cloudDestinations.isEmpty;

  String? get cloudFileName => localFile != null ? "$id${extension(localFile!.path)}" : null;

  bool get isAudio => type == AssetType.audio;
  bool get isImage => type == AssetType.image;
  bool get isVideo => type == AssetType.video;
  int? get durationInMs => (metadata?[DURATION_KEY] is int) ? metadata![DURATION_KEY] as int : null;

  double? get aspectRatio => (width != null && height != null && height! > 0) ? width! / height! : null;

  /// Format duration to readable string (MM:SS)
  String? get formattedDuration {
    final duration = durationInMs;
    if (duration == null) return null;

    final seconds = (duration ~/ 1000) % 60;
    final minutes = (duration ~/ (1000 * 60)) % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  File? get localFile {
    final possibleFile = File(localFilePath);
    if (possibleFile.existsSync()) return possibleFile;

    return null;
  }

  /// Get the storage path for this asset.
  ///
  /// Example output:
  /// - Image: `/support/dir/images/1762500783746.jpg`
  /// - Audio: `/support/dir/audio/1762500783746.m4a`
  String get localFilePath {
    return type.getStoragePath(
      id: id,
      extension: extension(originalSource),
    );
  }

  /// Get the relative storage path for this asset.
  /// This is used for storing paths in the database.
  /// Example output:
  /// - Image: `images/1762500783746.jpg`
  /// - Audio: `audio/1762500783746.m4a`
  String get relativeLocalFilePath {
    return type.getRelativeStoragePath(
      id: id,
      extension: extension(originalSource),
    );
  }

  factory AssetDbModel.fromLocalPath({
    required int id,
    required String localPath,
    required AssetType type,
    int? durationInMs,
    double? width,
    double? height,
    List<int>? tags,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();

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
      width: width,
      height: height,
      tags: tags,
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
    return cloudDestinations[BackupServiceType.google_drive.id]?.keys.toList();
  }

  String? getGoogleDriveUrlForEmail(String email) {
    final fileId = getGoogleDriveIdForEmail(email);
    if (fileId is String) {
      return "https://www.googleapis.com/drive/v3/files/$fileId?alt=media";
    }
    return null;
  }

  String? getGoogleDriveIdForEmail(String email) {
    return cloudDestinations[BackupServiceType.google_drive.id]?[email]?['file_id'];
  }

  /// Generic counterpart to [getGoogleDriveIdForEmail] — usable for any
  /// connected service, e.g. to check whether another already-signed-in
  /// service has this asset before it's ever been downloaded to this device.
  String? cloudFileIdFor({
    required BackupServiceType serviceType,
    required String identifier,
  }) {
    return cloudDestinations[serviceType.id]?[identifier]?['file_id'];
  }

  /// Every (serviceType, identifier, fileId) this asset has been uploaded
  /// to, across every connected service — unlike [getGoogleDriveIdForEmail]
  /// and friends, this isn't scoped to one provider. Used wherever an asset
  /// needs to be fully cleaned up or fully described: deleting it must
  /// remove every remote copy, not just Drive's, and the asset info sheet
  /// should list every destination, not just Drive's.
  List<({BackupServiceType serviceType, String identifier, String fileId})> get allCloudDestinations {
    final destinations = <({BackupServiceType serviceType, String identifier, String fileId})>[];

    for (final serviceType in BackupServiceType.values) {
      final forService = cloudDestinations[serviceType.id];
      if (forService == null) continue;

      for (final entry in forService.entries) {
        final fileId = entry.value['file_id'];
        if (fileId != null) {
          destinations.add((serviceType: serviceType, identifier: entry.key, fileId: fileId));
        }
      }
    }

    return destinations;
  }

  /// Every [allCloudDestinations] entry that matches a currently signed-in
  /// account, in the same order as [allCloudDestinations] — a destination
  /// left over from a since-switched account/folder doesn't count, since it
  /// can't be acted on with today's credentials. An asset can have valid
  /// copies on more than one connected service; callers that can retry
  /// (e.g. [BackupAssetDownloaderService]) should try each rather than
  /// assuming the first is the only option.
  List<({BackupServiceType serviceType, String identifier, String fileId})> matchingCloudDestinationsFor(
    List<BackupCloudService> signedInServices,
  ) {
    return allCloudDestinations
        .where(
          (d) => signedInServices.any(
            (s) => s.serviceType == d.serviceType && s.currentUser?.destinationKey == d.identifier,
          ),
        )
        .toList();
  }

  /// The first of [matchingCloudDestinationsFor], if any — for callers that
  /// only need to know whether *some* destination is reachable (e.g. the
  /// Library status badges, the export view model's downloadable check),
  /// not which ones or in what order.
  ({BackupServiceType serviceType, String identifier, String fileId})? matchingCloudDestinationFor(
    List<BackupCloudService> signedInServices,
  ) {
    return matchingCloudDestinationsFor(signedInServices).firstOrNull;
  }

  Future<AssetDbModel?> save({
    bool runCallbacks = true,
  }) async => db.set(this, runCallbacks: runCallbacks);

  Future<void> delete({
    bool runCallbacks = true,
  }) async => db.delete(
    id,
    runCallbacks: runCallbacks,
  );

  /// Find an asset by its relative file path
  ///
  /// Supports relative paths for both image and audio:
  /// - images/{id}.jpg
  /// - audio/{id}.m4a
  static Future<AssetDbModel?> findBy({
    required String relativePath,
  }) async {
    final id = AssetType.parseAssetId(relativePath);
    return id != null ? AssetDbModel.db.find(id) : null;
  }

  AssetDbModel copyWithCloudFile({
    required BackupServiceType serviceType,
    required CloudFileObject cloudFile,
    required String email,
  }) {
    Map<String, Map<String, Map<String, String>>> newCloudDestinations = {...cloudDestinations};

    newCloudDestinations[serviceType.id] ??= {};
    newCloudDestinations[serviceType.id]![email] = {
      'file_id': cloudFile.id,
      'file_name': cloudFile.fileName!,
    };

    return copyWith(
      cloudDestinations: newCloudDestinations,
      updatedAt: DateTime.now(),
    );
  }

  /// Removal counterpart to [copyWithCloudFile] — drops a single stale
  /// destination (e.g. once a download 404 confirms the remote copy is
  /// actually gone), so [pendingAssets]-style lookups stop treating this
  /// service+identifier as a valid source/destination for this asset.
  AssetDbModel copyWithoutCloudFile({
    required BackupServiceType serviceType,
    required String identifier,
  }) {
    Map<String, Map<String, Map<String, String>>> newCloudDestinations = {...cloudDestinations};

    final forService = newCloudDestinations[serviceType.id];
    if (forService != null && forService.containsKey(identifier)) {
      newCloudDestinations[serviceType.id] = {...forService}..remove(identifier);
    }

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
