import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:path/path.dart';
import 'package:storypad/core/databases/adapters/objectbox/assets_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/initializers/file_initializer.dart';

part 'asset_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class AssetDbModel extends BaseDbModel {
  static final AssetsBox db = AssetsBox();

  @override
  final int id;
  final String originalSource;
  final Map<String, dynamic> cloudDestinations;

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

  File? get localFile {
    final file = File(originalSource);
    if (file.existsSync()) return file;

    final fileName = basename(originalSource);
    final possibleFile = File("${kApplicationDirectory.path}/images/$fileName");
    if (possibleFile.existsSync()) return possibleFile;

    return null;
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

  Future<AssetDbModel?> save() async => db.set(this);
  Future<void> delete() async => db.delete(id);

  factory AssetDbModel.fromJson(Map<String, dynamic> json) => _$AssetDbModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AssetDbModelToJson(this);
}
