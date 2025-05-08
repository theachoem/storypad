import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/assets_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backup_sources/google_drive_backup_source.dart';

part 'asset_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class AssetDbModel extends BaseDbModel {
  static final AssetsBox db = AssetsBox();

  @override
  final int id;
  final String originalSource;
  final Map<String, Map<String, Map<String, String>>> cloudDestinations;

  final DateTime createdAt;

  @override
  final DateTime updatedAt;
  final String? lastSavedDeviceId;

  AssetDbModel({
    required this.id,
    required this.originalSource,
    required this.cloudDestinations,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSavedDeviceId,
  });

  bool get needBackup => !originalSource.startsWith("http") && cloudDestinations.isEmpty;

  String? get cloudFileName => localFile != null ? "$id${extension(localFile!.path)}" : null;

  // This link is to put inside embed block.
  String get link => "storypad://assets/$id";

  File? get localFile {
    final file = File(originalSource);
    if (file.existsSync()) return file;

    final possibleFile = File(downloadFilePath);
    if (possibleFile.existsSync()) return possibleFile;

    return null;
  }

  String get downloadFilePath {
    final fileName = basename(originalSource);
    return "${kSupportDirectory.path}/images/$fileName";
  }

  factory AssetDbModel.fromLocalPath({
    required int id,
    required String localPath,
  }) {
    final now = DateTime.now();

    return AssetDbModel(
      id: id,
      originalSource: localPath,
      cloudDestinations: {},
      createdAt: now,
      updatedAt: now,
      lastSavedDeviceId: null,
    );
  }

  bool isGoogleDriveUploadedFor(String? email) {
    return getGoogleDriveIdForEmail(email ?? '') != null;
  }

  List<String>? getGoogleDriveForEmails() {
    return cloudDestinations[GoogleDriveBackupSource().cloudId]?.keys.toList();
  }

  String? getGoogleDriveUrlForEmail(String email) {
    final fileId = getGoogleDriveIdForEmail(email);
    if (fileId is String) {
      return "https://www.googleapis.com/drive/v3/files/$fileId?alt=media";
    }
    return null;
  }

  String? getGoogleDriveIdForEmail(String email) {
    final service = GoogleDriveBackupSource();
    return cloudDestinations[service.cloudId]?[email]?['file_id'];
  }

  Future<AssetDbModel?> save() async => db.set(this);
  Future<void> delete() async => db.delete(id);

  static Future<AssetDbModel?> findBy({
    required String assetLink,
  }) async {
    int? id = int.tryParse(assetLink.split("storypad://assets/").lastOrNull ?? '');
    return id != null ? AssetDbModel.db.find(id) : null;
  }

  AssetDbModel copyWithGoogleDriveCloudFile({
    required CloudFileObject cloudFile,
  }) {
    Map<String, Map<String, Map<String, String>>> newCloudDestinations = {...cloudDestinations};
    final service = GoogleDriveBackupSource();

    newCloudDestinations[service.cloudId] ??= {};
    newCloudDestinations[service.cloudId]![service.email!] = {
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
