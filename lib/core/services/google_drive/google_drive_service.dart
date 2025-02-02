// ignore_for_file: depend_on_referenced_packages

import 'dart:async' show Completer;
import 'dart:convert' show utf8;
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show basename;
import 'package:storypad/core/objects/cloud_file_list_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';

part 'google_auth_client.dart';

class GoogleDriveService {
  GoogleDriveService._();

  int requestCount = 0;
  Map<String, String> folderDriveIdByFolderName = {};

  static final instance = GoogleDriveService._();

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

  Future<CloudFileObject?> fetchLatestFile() async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      drive.FileList fileList = await client.files.list(
        spaces: "appDataFolder",
        q: "name contains '.json'",
        orderBy: "createdTime desc",
        pageSize: 1,
      );

      if (fileList.files?.firstOrNull == null) return null;
      return CloudFileObject.fromGoogleDrive(fileList.files!.first);
    });
  }

  Future<CloudFileListObject?> fetchAll(String? nextToken) async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      drive.FileList fileList = await client.files.list(
        q: "name contains '.json'",
        spaces: "appDataFolder",
        pageToken: nextToken,
      );

      return CloudFileListObject.fromGoogleDrive(fileList);
    });
  }

  Future<CloudFileObject?> fetchLegacyStoryPadBackup() async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      const mimeType = "mimeType = 'application/vnd.google-apps.folder'";
      drive.FileList? folderList = await client.files.list(q: mimeType);

      String? folderId;
      folderList.files?.forEach((e) {
        if (e.name == "Story") folderId = e.id;
      });

      final folder = await client.files.list(
        q: "mimeType = 'application/zip' and '$folderId' in parents",
      );

      drive.File? file = folder.files?.firstOrNull;
      return file != null ? CloudFileObject.fromLegacyStoryPad(file) : null;
    });
  }

  Future<CloudFileObject?> findFileById(String fileId) async {
    return _execHandler(() async {
      drive.DriveApi? client = await googleDriveClient;
      if (client == null) return null;

      Object file = await client.files.get(fileId);
      if (file is drive.File) {
        return CloudFileObject.fromGoogleDrive(file);
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
          return CloudFileObject.fromGoogleDrive(lastFile);
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

  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async {
    return _execHandler(() async {
      debugPrint('GoogleDriveService#uploadFile $fileName');
      drive.DriveApi? client = await googleDriveClient;

      if (client == null) return null;

      drive.File fileToUpload = drive.File();
      fileToUpload.name = fileName;
      fileToUpload.parents = ["appDataFolder"];

      if (folderName != null) {
        String? folderId = await loadFolder(client, folderName);
        if (folderId == null) return null;
        fileToUpload.parents = [folderId];
      }

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
        return CloudFileObject.fromGoogleDrive(recieved);
      }

      debugPrint('GoogleDriveService#uploadFile uploading failed!');
      return null;
    });
  }

  Future<String?> loadFolder(drive.DriveApi client, String folderName) async {
    if (folderDriveIdByFolderName[folderName] != null) return folderDriveIdByFolderName[folderName];

    drive.FileList response = await client.files.list(
      spaces: "appDataFolder",
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder'",
    );

    if (response.files?.firstOrNull?.id != null) {
      debugPrint("Drive folder ${response.files!.first.name} founded: ${response.files!.first.id}");
      return folderDriveIdByFolderName[folderName] = response.files!.first.id!;
    }

    drive.File folderToCreate = drive.File();
    folderToCreate.name = folderName;
    folderToCreate.parents = ["appDataFolder"];
    folderToCreate.mimeType = "application/vnd.google-apps.folder";

    final createdFolder = await client.files.create(folderToCreate);
    debugPrint("Drive folder ${createdFolder.name} created: ${createdFolder.id}");

    return folderDriveIdByFolderName[folderName] = createdFolder.id!;
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
    requestCount++;

    return request().onError((e, stackTrace) async {
      debugPrintStack(stackTrace: stackTrace);

      if (e is drive.DetailedApiRequestError) {
        if (e.status == 401) {
          await googleSignIn.signInSilently(reAuthenticate: true);
          requestCount++;
          return request();
        }
      }

      return null;
    });
  }
}
