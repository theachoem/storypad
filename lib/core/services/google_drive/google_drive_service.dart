// ignore_for_file: depend_on_referenced_packages

import 'dart:async' show Completer;
import 'dart:convert' show utf8;
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show basename;
import 'package:spooky/core/objects/cloud_file_list_object.dart';
import 'package:spooky/core/objects/cloud_file_object.dart';

part 'google_auth_client.dart';

class GoogleDriveService {
  final GoogleSignIn googleSignIn = GoogleSignIn.standard(
    scopes: [drive.DriveApi.driveAppdataScope, drive.DriveApi.driveFileScope],
  );

  Future<drive.DriveApi?> get googleDriveClient async {
    if (googleSignIn.currentUser == null) return null;
    final _GoogleAuthClient client = _GoogleAuthClient(await googleSignIn.currentUser!.authHeaders);
    return drive.DriveApi(client);
  }

  Future<bool> isUploaded(io.File file) async {
    String fileName = basename(file.path);
    CloudFileObject? cloudFile = await findFileByName(fileName);
    if (cloudFile == null) return false;

    String? cloudContent = await getFileContent(cloudFile);
    String localContent = await file.readAsString();

    return cloudContent.hashCode == localContent.hashCode;
  }

  Future<CloudFileListObject?> fetchAll(String? nextToken) async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      drive.FileList fileList = await client.files.list(
        spaces: "appDataFolder",
        pageToken: nextToken,
      );

      return CloudFileListObject.fromGoogleDrive(fileList);
    });
  }

  Future<CloudFileObject?> findFileById(String fileId) async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      Object file = await client.files.get(fileId);
      if (file is drive.File) {
        return CloudFileObject.fromGooglDrive(file);
      }

      return null;
    });
  }

  Future<CloudFileObject?> findFileByName(String fileName) async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      drive.FileList? fileList = await client.files.list(
        q: "name = '$fileName'",
        spaces: "appDataFolder",
      );

      List<drive.File>? files = fileList.files;
      if (files != null && files.isNotEmpty == true) {
        drive.File? lastFile = files.lastOrNull;

        if (lastFile != null && lastFile.id != null) {
          return CloudFileObject.fromGooglDrive(lastFile);
        }
      }

      return null;
    });
  }

  Future<CloudFileObject?> delete(String fileId) async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      await client.files.delete(fileId);
      return CloudFileObject(id: fileId, fileName: null, description: null);
    });
  }

  Future<CloudFileObject?> uploadFile(String fileName, io.File file) async {
    return _execHandler(() async {
      debugPrint('GoogleDriveService#uploadFile $fileName');
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      drive.File fileToUpload = drive.File();
      fileToUpload.name = fileName;
      fileToUpload.parents = ["appDataFolder"];

      debugPrint('GoogleDriveService#uploadFile uploading...');
      drive.File recieved = await client.files.create(
        fileToUpload,
        uploadMedia: drive.Media(
          file.openRead(),
          file.lengthSync(),
        ),
      );

      if (recieved.id != null) {
        debugPrint('GoogleDriveService#uploadFile uploaded: ${recieved.id}');
        return CloudFileObject.fromGooglDrive(recieved);
      }

      debugPrint('GoogleDriveService#uploadFile uploading failed!');
      return null;
    });
  }

  Future<String?> getFileContent(CloudFileObject file) async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      CloudFileObject? fileInfo = await findFileById(file.id);
      if (fileInfo == null) return null;

      Object? media = await client.files.get(fileInfo.id, downloadOptions: drive.DownloadOptions.fullMedia);
      if (media is drive.Media) {
        List<int> dataStore = [];

        Completer completer = Completer();
        media.stream.listen(
          (data) => dataStore.insertAll(dataStore.length, data),
          onDone: () => completer.complete(utf8.decode(dataStore)),
          onError: (error) {},
        );

        await completer.future;
        return utf8.decode(dataStore);
      }

      return null;
    });
  }

  Future<T?> _execHandler<T>(Future<T?> Function() request) async {
    return request().onError((e, stackTrace) async {
      debugPrintStack(stackTrace: stackTrace);

      if (e is drive.DetailedApiRequestError) {
        if (e.status == 401) {
          await googleSignIn.signInSilently(reAuthenticate: true);
          return request();
        }
      }

      return null;
    });
  }
}
