import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/constants/app_constants.dart';

// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:storypad/core/services/logger/app_logger.dart';

enum FirestoreStorageState { success, connectionFailed, unauthorized, unknown }

class FirestoreStorageResponse {
  final File? file;
  final FirestoreStorageState state;

  bool get success => file != null;
  bool get unauthorized => state == FirestoreStorageState.unauthorized;
  bool get connectionFailed => state == FirestoreStorageState.connectionFailed;

  FirestoreStorageResponse({
    required this.file,
    this.state = FirestoreStorageState.success,
  });
}

class FirestoreStorageService {
  // ignore: constant_identifier_names
  static const int MAX_DOWNLOAD_SIZE = 20 * 1024 * 1024; // 20mb

  static FirestoreStorageService instance = FirestoreStorageService();

  Map<String, dynamic>? _hash;
  Map<String, String>? _downloadUrlsByUrlPath;

  final Map<String, Completer<FirestoreStorageResponse>> _downloadingFileByUrlPath = {};

  Future<Map<String, dynamic>?> get hash async =>
      _hash ??= await rootBundle.loadString('assets/firestore_storage_map.json').then((jsonString) {
        return json.decode(jsonString);
      });

  // input: /relax_sounds/animal/forest_birds.svg"
  // output: /relax_sounds/animal/forest_birds-8ce3ba7e37ca67690cc3c180abfdffc8.svg"
  Future<String> getHashPath(String originalUrlPath) async {
    return (await hash)?[originalUrlPath];
  }

  Future<File?> getCachedFile(String urlPath) async {
    final String hashPath = await getHashPath(urlPath);
    final String downloadPath = constructDeviceDownloadPath(hashPath);

    if (File(downloadPath).existsSync()) return File(downloadPath);

    return null;
  }

  Future<String?> getDownloadURL(String urlPath) async {
    _downloadUrlsByUrlPath ??= {};

    try {
      if (_downloadUrlsByUrlPath?[urlPath] != null) return _downloadUrlsByUrlPath?[urlPath];

      final storageRef = FirebaseStorage.instance.ref();
      final String hashPath = await getHashPath(urlPath);
      final childRef = storageRef.child(hashPath);

      return _downloadUrlsByUrlPath?[urlPath] = await childRef.getDownloadURL();
    } on FirebaseException catch (e, s) {
      // https://firebase.google.com/docs/storage/flutter/handle-errors
      AppLogger.error(
        "FirestoreStorageService#getDownloadURL code: ${e.code}, message: ${e.message}, plugin: ${e.plugin}",
        stackTrace: s,
      );
      return null;
    } catch (e, s) {
      AppLogger.error(e.toString(), stackTrace: s);
      return null;
    }
  }

  // max download is 20mb, we will validate during uploading in:
  // bin/firebase_admin/upload_files_to_firestore_storages.js
  Future<FirestoreStorageResponse> downloadFile(String urlPath) async {
    assert(urlPath.startsWith("/"));

    final storageRef = FirebaseStorage.instance.ref();
    final String hashPath = await getHashPath(urlPath);
    final String downloadPath = constructDeviceDownloadPath(hashPath);

    if (File(downloadPath).existsSync()) return FirestoreStorageResponse(file: File(downloadPath));
    if (!File(downloadPath).parent.existsSync()) await File(downloadPath).parent.create(recursive: true);

    if (_downloadingFileByUrlPath[urlPath] != null && !_downloadingFileByUrlPath[urlPath]!.isCompleted) {
      return _downloadingFileByUrlPath[urlPath]!.future;
    }

    _downloadingFileByUrlPath[urlPath] = Completer<FirestoreStorageResponse>();

    final childRef = storageRef.child(hashPath);

    FirestoreStorageResponse? response;
    try {
      final content = await childRef.getData(MAX_DOWNLOAD_SIZE);

      if (content != null) {
        await File(downloadPath).writeAsBytes(content);
        response = FirestoreStorageResponse(file: File(downloadPath));
      }
    } on FirebaseException catch (e, s) {
      AppLogger.error(
        "🔴 FirestoreStorageService#downloadFile code: ${e.code}, message: ${e.message}, plugin: ${e.plugin}",
        stackTrace: s,
      );
      if (e.code == 'unauthorized') {
        response = FirestoreStorageResponse(
          file: null,
          state: FirestoreStorageState.unauthorized,
        );
      }
    } catch (e, s) {
      AppLogger.error("🔴 FirestoreStorageService#downloadFile code: $e", stackTrace: s);
    }

    response ??= FirestoreStorageResponse(file: null, state: FirestoreStorageState.unknown);
    _downloadingFileByUrlPath[urlPath]?.complete(response);
    return response;
  }

  String constructDeviceDownloadPath(String path) {
    return '${kSupportDirectory.path}/downloaded_from_firestore$path';
  }

  /// Cleans up any downloaded files that are no longer referenced in the assets map.
  /// Returns a list of paths that were deleted.
  Future<List<String>> cleanupUnusedFiles() async {
    try {
      final downloadDir = Directory('${kSupportDirectory.path}/downloaded_from_firestore');
      if (!await downloadDir.exists()) return [];

      // {
      //   "/relax_sounds/water/ocean_waves-130d1d326a06fe0f21d4650a4f7065b7.txt",
      //   "/relax_sounds/water/droplets-ec36e00209a8cece33eef6f5c3f80e61.txt",
      // };
      final validBasenames = (await hash ?? {}).values.map((e) => path.basename(e.toString())).toSet();

      final files = await downloadDir.list(recursive: true).where((entity) => entity is File).toList();
      final deletedFiles = <String>[];

      for (final fileEntity in files) {
        final filename = path.basename(fileEntity.path);

        if (validBasenames.contains(filename)) continue;

        try {
          await fileEntity.delete();
          deletedFiles.add(filename);
        } catch (e, s) {
          AppLogger.error(
            '$runtimeType#cleanupUnusedFiles failed to delete file ${fileEntity.path}: $e',
            stackTrace: s,
          );
        }
      }

      AppLogger.info('$runtimeType#cleanupUnusedFiles ${deletedFiles.length} unused files removed');
      return deletedFiles;
    } catch (e, s) {
      AppLogger.error('$runtimeType#cleanupUnusedFiles error: $e', stackTrace: s);
      return [];
    }
  }
}
