// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/remote_storage_clients/storage_client_exception.dart';
import 'package:storypad/core/remote_storage_clients/base_storage_client.dart';
import 'package:googleapis/drive/v3.dart' as drive;

// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:storypad/core/local_storages/google_drive_file_id_by_name_storage.dart';
import 'package:storypad/core/local_storages/google_drive_folder_id_by_name_storage.dart';
import 'package:storypad/core/local_storages/google_user_storage.dart';

class GoogleDriveStorageClient extends BaseStorageClient {
  static const String CLIENT_ID = 'google_drive';
  static const List<String> SCOPES = [drive.DriveApi.driveAppdataScope];

  final GoogleDriveFileIdByNameStorage _fileIdByNameStorage = GoogleDriveFileIdByNameStorage();
  final GoogleDriveFolderIdByNameStorage _folderIdByNameStorage = GoogleDriveFolderIdByNameStorage();

  @override
  String get id => CLIENT_ID;

  @override
  bool get supportSignOut => true;

  @override
  Future<void> authenticate() async {
    try {
      GoogleSignInAccount account = await (await _googleSignIn).authenticate();
      GoogleSignInClientAuthorization? authorization = await account.authorizationClient.authorizationForScopes(SCOPES);
      await _setUser(account, authorization);

      if (authorization?.accessToken == null) {
        throw StorageClientException.unauthorizedMissingScope();
      }
    } on StorageClientException catch (_) {
      rethrow;
    } on SocketException catch (_) {
      throw StorageClientException.noInternet();
    } on GoogleSignInException catch (e) {
      throw StorageClientException.requestFailed(e);
    } catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    }
  }

  @override
  Future<void> signOut() async {
    await (await _googleSignIn).signOut();
    await _clearUser();
  }

  @override
  FutureOr<bool> isAuthenticated() async {
    return await GoogleUserStorage().readObject() != null;
  }

  @override
  Future<void> delete({
    Folder? remoteFileFolder,
    required String remoteFileName,
  }) async {
    final client = _googleDriveClient;
    if (client == null) throw StorageClientException.requestFailed();

    try {
      String? fileId = await _loadFileId(client, remoteFileFolder, remoteFileName);
      if (fileId == null) throw StorageClientException.unknownError();

      await requestWrapper(
        callback: () => client.files.delete(fileId!),
        on404: () async {
          fileId = await _loadFileId(client, remoteFileFolder, remoteFileName, clearCache: true);
          if (fileId == null) return;
          return client.files.delete(fileId!);
        },
      );
    } on StorageClientException catch (_) {
      rethrow;
    } on SocketException catch (_) {
      throw StorageClientException.noInternet();
    } on drive.DetailedApiRequestError catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    } catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    }
  }

  @override
  Future<void> download({
    Folder? remoteFileFolder,
    required String remoteFileName,
    required String destinationFilePath,
  }) async {
    final client = _googleDriveClient;
    if (client == null) throw StorageClientException.requestFailed();

    try {
      String? fileId = await _loadFileId(client, remoteFileFolder, remoteFileName);
      if (fileId == null) throw StorageClientException.unknownError();

      Object? media = await requestWrapper(
        callback: () => client.files.get(fileId!, downloadOptions: drive.DownloadOptions.fullMedia),
        on404: () async {
          fileId = await _loadFileId(client, remoteFileFolder, remoteFileName, clearCache: true);
          if (fileId == null) return null;
          return client.files.get(fileId!, downloadOptions: drive.DownloadOptions.fullMedia);
        },
      );

      if (media is! drive.Media) throw StorageClientException.requestFailed();

      List<int> fileBytes = [];
      Completer completer = Completer();

      media.stream.listen(
        (data) => fileBytes.insertAll(fileBytes.length, data),
        onDone: () => completer.complete(fileBytes),
        onError: (error) => completer.completeError(StorageClientException.unknownError(error)),
      );

      await completer.future;

      final file = File(destinationFilePath);
      if (await file.parent.exists() == false) await file.parent.create(recursive: true);
      await file.writeAsBytes(fileBytes);
    } on StorageClientException catch (_) {
      rethrow;
    } on SocketException catch (_) {
      throw StorageClientException.noInternet();
    } on drive.DetailedApiRequestError catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    } catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    }
  }

  @override
  Future<List<RemoteFile>> list([
    Folder? folder,
  ]) async {
    final client = _googleDriveClient;
    if (client == null) throw StorageClientException.requestFailed();

    try {
      String? folderId;
      if (folder != null) folderId = await _loadFolderId(client, folder);

      String query = "name contains '.json' or name contains '.zip'";
      if (folderId != null) query = "($query) and '$folderId' in parents";
      drive.FileList fileList = await client.files.list(q: query, spaces: "appDataFolder");
      if (fileList.files == null) return [];

      for (var files in fileList.files!) {
        if (files.name == null) continue;
        String cacheKey = getCacheKey(folder, files.name!);
        await _fileIdByNameStorage.setValue(cacheKey, files.id!);
      }

      return fileList.files!.map((e) {
        return RemoteFile(
          title: e.name,
          bytesSize: e.size != null ? int.tryParse(e.size!) : null,
          lastSyncDate: e.modifiedTime,
          path: [
            if (folder != null) folder.name,
            if (e.name != null) e.name,
          ].join("/"),
        );
      }).toList();
    } on StorageClientException catch (_) {
      rethrow;
    } on SocketException catch (_) {
      throw StorageClientException.noInternet();
    } on drive.DetailedApiRequestError catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    } catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    }
  }

  @override
  Future<void> upload({
    required String sourceFilePath,
    Folder? remoteFileFolder,
    required String remoteFileName,
  }) async {
    final client = _googleDriveClient;
    if (client == null) throw StorageClientException.requestFailed();

    try {
      String? folderId;
      if (remoteFileFolder != null) folderId = await _loadFolderId(client, remoteFileFolder);

      drive.File fileToUpload = drive.File();
      fileToUpload.name = remoteFileName;
      fileToUpload.parents = folderId != null ? ["appDataFolder", folderId] : ["appDataFolder"];

      drive.File uploadedFile = await client.files.create(
        fileToUpload,
        uploadMedia: drive.Media(
          File(sourceFilePath).openRead(),
          await File(sourceFilePath).length(),
        ),
      );

      if (uploadedFile.id == null) throw StorageClientException.requestFailed();
      String cacheKey = getCacheKey(remoteFileFolder, remoteFileName);
      await _fileIdByNameStorage.setValue(cacheKey, uploadedFile.id!);
    } on StorageClientException catch (_) {
      rethrow;
    } on SocketException catch (_) {
      throw StorageClientException.noInternet();
    } on drive.DetailedApiRequestError catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    } catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    }
  }

  // private

  GoogleUserObject? _currentUser;
  GoogleUserObject? get currentUser => _currentUser;

  GoogleSignInAccount? _googleSignInAccount;
  GoogleSignInAccount? get googleSignInAccount => _googleSignInAccount;

  Completer<GoogleSignIn>? _googleSignInCompleter;
  Future<GoogleSignIn> get _googleSignIn async {
    if (_googleSignInCompleter != null) return _googleSignInCompleter!.future;
    _googleSignInCompleter = Completer();

    GoogleSignIn.instance.initialize().then((_) {
      _googleSignInCompleter!.complete(GoogleSignIn.instance);
    });

    return _googleSignInCompleter!.future;
  }

  drive.DriveApi? get _googleDriveClient {
    if (currentUser == null) return null;
    final _GoogleAuthClient client = _GoogleAuthClient(currentUser!.authHeaders);
    return drive.DriveApi(client);
  }

  Future<void> _setUser(GoogleSignInAccount account, GoogleSignInClientAuthorization? authorization) async {
    _googleSignInAccount = account;
    _currentUser = GoogleUserObject(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      accessToken: authorization?.accessToken,
      refreshedAt: DateTime.now(),
    );
    await GoogleUserStorage().writeObject(_currentUser!);
  }

  Future<String?> _loadFileId(
    drive.DriveApi client,
    Folder? remoteFileFolder,
    String remoteFileName, {
    bool clearCache = false,
  }) async {
    String cacheKey = getCacheKey(remoteFileFolder, remoteFileName);
    if (clearCache) await _fileIdByNameStorage.removeValue(cacheKey);

    String? folderId;
    if (remoteFileFolder != null) folderId = await _loadFolderId(client, remoteFileFolder);

    String? fileId = await _fileIdByNameStorage.getValue<String>(cacheKey);
    if (fileId != null) return fileId;

    drive.FileList response = folderId != null
        ? await client.files.list(spaces: "appDataFolder", q: "name='$remoteFileName' and '$folderId' in parents")
        : await client.files.list(spaces: "appDataFolder", q: "name='$remoteFileName'");

    fileId = response.files?.firstOrNull?.id;
    if (fileId == null) return null;

    debugPrint("Drive file '${response.files!.first.name}' found with ID: $fileId");
    await _fileIdByNameStorage.setValue(cacheKey, fileId);
    return fileId;
  }

  String getCacheKey(Folder? remoteFileFolder, String remoteFileName) {
    String cacheKey = [if (remoteFileFolder != null) remoteFileFolder.name, remoteFileName].join("/");
    return cacheKey;
  }

  Future<String> _loadFolderId(drive.DriveApi client, Folder folder) async {
    String? folderId = await _folderIdByNameStorage.getValue<String>(folder.name);
    if (folderId != null) return folderId;

    drive.FileList response = await client.files.list(
      spaces: "appDataFolder",
      q: "name='${folder.name}' and mimeType='application/vnd.google-apps.folder'",
    );

    folderId = response.files?.firstOrNull?.id;
    if (folderId != null) {
      debugPrint("Drive folder '${response.files!.first.name}' found with ID: $folderId");
      await _folderIdByNameStorage.setValue(folder.name, folderId);
      return folderId;
    }

    drive.File folderToCreate = drive.File();
    folderToCreate.name = folder.name;
    folderToCreate.parents = ["appDataFolder"];
    folderToCreate.mimeType = "application/vnd.google-apps.folder";

    final createdFolder = await client.files.create(folderToCreate);
    if (createdFolder.id == null) throw StorageClientException.requestFailed();
    debugPrint("Created new Drive folder '${createdFolder.name}' with ID: ${createdFolder.id}");

    folderId = createdFolder.id!;
    await _folderIdByNameStorage.setValue(folder.name, folderId);
    return folderId;
  }

  Future<void> _clearUser() async {
    _googleSignInAccount = null;
    _currentUser = null;
    await GoogleUserStorage().remove();
  }

  Future<T> requestWrapper<T>({
    required Future<T> Function() callback,
    required Future<T> Function() on404,
  }) async {
    try {
      return callback();
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) return on404();
      rethrow;
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final http.Client client = http.Client();
  final Map<String, String> headers;

  _GoogleAuthClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return client.send(request..headers.addAll(headers));
  }
}
