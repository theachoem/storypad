import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/task_queue_service.dart';

enum FirestoreStorageState {
  success,
  connectionFailed,
  unauthorized,
  unknown;
}

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
  static FirestoreStorageService instance = FirestoreStorageService();
  final TaskQueueService _queueDownload = TaskQueueService();

  // input: /relax_sounds/animal/forest_birds.svg"
  // output: /relax_sounds/animal/forest_birds-8ce3ba7e37ca67690cc3c180abfdffc8.svg"
  Future<String> getHashPath(String originalFilePath) async {
    final String jsonString = await rootBundle.loadString('assets/firestore_storage_map.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return jsonData[originalFilePath];
  }

  Future<File?> getCachedFile(String path) async {
    String downloadPath = constructDownloadPath(path);
    if (File(downloadPath).existsSync()) return File(downloadPath);
    return null;
  }

  Future<FirestoreStorageResponse> queueDownloadFile(String path) async {
    FirestoreStorageResponse? response;

    await _queueDownload.addTask(() async {
      response = await downloadFile(path);
    });

    return response ?? FirestoreStorageResponse(file: null, state: FirestoreStorageState.unknown);
  }

  // max download is 10mb, we will validate during uploading in:
  // bin/firebase_admin/upload_files_to_firestore_storages.js
  Future<FirestoreStorageResponse> downloadFile(String path) async {
    assert(path.startsWith("/"));

    final storageRef = FirebaseStorage.instance.ref();
    final childRef = storageRef.child(await getHashPath(path));

    String downloadPath = constructDownloadPath(path);
    if (File(downloadPath).existsSync()) return FirestoreStorageResponse(file: File(downloadPath));
    if (!File(downloadPath).parent.existsSync()) File(downloadPath).parent.createSync(recursive: true);

    try {
      final content = await childRef.getData();

      if (content != null) {
        await File(downloadPath).writeAsBytes(content);
        return FirestoreStorageResponse(file: File(downloadPath));
      }
    } on FirebaseException catch (e) {
      debugPrint("🔴 FirestoreStorageService#downloadFile code: ${e.code}, message: ${e.message}, plugin: ${e.plugin}");
      if (e.code == 'unauthorized') {
        return FirestoreStorageResponse(
          file: null,
          state: FirestoreStorageState.unauthorized,
        );
      }
    } catch (e) {
      debugPrint("🔴 FirestoreStorageService#downloadFile code: $e");
    }

    return FirestoreStorageResponse(file: null, state: FirestoreStorageState.unknown);
  }

  String constructDownloadPath(String path) {
    return '${kSupportDirectory.path}/downloaded_from_firestore$path';
  }
}
