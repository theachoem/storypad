import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:storypad/core/exceptions/google_drive_exceptions.dart';
import 'package:storypad/core/objects/cloud_file_list_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/storages/google_user_storage.dart';

// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class _GoogleAuthClient extends http.BaseClient {
  final http.Client client = http.Client();
  final Map<String, String> headers;

  _GoogleAuthClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return client.send(request..headers.addAll(headers));
  }
}

// This class is responsible for calling Google Drive APIs.
// It should throw exceptions for all failures - let repository handle error conversion.
class GoogleDriveClient {
  GoogleUserObject? _currentUser;
  GoogleUserObject? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  final Map<String, String> _folderDriveIdByFolderName = {};

  final GoogleSignIn googleSignIn = GoogleSignIn.standard(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  Future<drive.DriveApi> get googleDriveClient async {
    if (googleSignIn.currentUser == null) {
      throw GoogleDriveAuthException.notSignedIn();
    }
    
    try {
      final authHeaders = await googleSignIn.currentUser!.authHeaders;
      final client = _GoogleAuthClient(authHeaders);
      return drive.DriveApi(client);
    } catch (e) {
      throw GoogleDriveAuthException.tokenRefreshFailed(e);
    }
  }

  Future<void> loadUserLocally() async {
    _currentUser = await GoogleUserStorage().readObject();
  }

  Future<bool> reauthenticateIfNeeded() async {
    try {
      _currentUser = await GoogleUserStorage().readObject();
      if (currentUser == null) return false;

      if (!await googleSignIn.isSignedIn()) {
        _currentUser = null;
        await GoogleUserStorage().remove();
        return false;
      }

      final account = await googleSignIn.signInSilently(
        reAuthenticate: currentUser == null || !currentUser!.isRefreshedRecently(),
        suppressErrors: false,
      );

      if (account != null) {
        final authentication = await account.authentication;
        _currentUser = GoogleUserObject(
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          accessToken: authentication.accessToken,
          refreshedAt: DateTime.now(),
        );

        await GoogleUserStorage().writeObject(_currentUser!);
        return true;
      }

      return false;
    } catch (e) {
      throw GoogleDriveAuthException.tokenRefreshFailed(e);
    }
  }

  Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw GoogleDriveAuthException.signInCancelled();
      }

      final authentication = await account.authentication;
      _currentUser = GoogleUserObject(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: authentication.accessToken,
        refreshedAt: DateTime.now(),
      );

      await GoogleUserStorage().writeObject(_currentUser!);
      return true;
    } catch (e) {
      if (e is GoogleDriveAuthException) rethrow;
      throw GoogleDriveAuthException('Sign in failed: ${e.toString()}', originalError: e);
    }
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await GoogleUserStorage().remove();
      _currentUser = null;
    } catch (e) {
      throw GoogleDriveAuthException('Sign out failed: ${e.toString()}', originalError: e);
    }
  }

  Future<bool> canAccessRequestedScopes() async {
    final user = googleSignIn.currentUser;
    if (user == null) {
      throw GoogleDriveAuthException.notSignedIn();
    }

    try {
      final authentication = await user.authentication;
      final accessToken = authentication.accessToken;
      if (accessToken == null) {
        throw GoogleDriveAuthException.tokenExpired();
      }

      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=$accessToken'),
      );
      
      if (response.statusCode != 200) {
        throw GoogleDriveNetworkException('Failed to verify token: ${response.statusCode}');
      }
      
      final Map<String, dynamic> tokenInfo = json.decode(response.body);
      final String? accessedScopes = tokenInfo['scope'] as String?;

      return googleSignIn.scopes.every((requestedScope) {
        return accessedScopes?.contains(requestedScope) ?? false;
      });
    } on http.ClientException catch (e) {
      throw GoogleDriveNetworkException.networkError(e);
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveApiException('Failed to check scopes: ${e.toString()}', originalError: e);
    }
  }

  Future<bool> requestScope() async {
    if (!isSignedIn) {
      throw GoogleDriveAuthException.notSignedIn();
    }

    try {
      final bool requested = await googleSignIn.requestScopes(googleSignIn.scopes);
      final bool authorized = await canAccessRequestedScopes();

      // If we request scope success but still unauthorized, it means user can disconnect app from Google app directly.
      if (requested && !authorized) {
        await googleSignIn.disconnect();
        _currentUser = null;
        await GoogleUserStorage().remove();
        throw GoogleDriveAuthException.insufficientPermissions();
      }

      // After request, access token might be renewed.
      final account = googleSignIn.currentUser;
      if (authorized && account != null) {
        final authentication = await account.authentication;
        _currentUser = GoogleUserObject(
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          accessToken: authentication.accessToken,
          refreshedAt: DateTime.now(),
        );
        await GoogleUserStorage().writeObject(_currentUser!);
      }

      return authorized;
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveAuthException('Failed to request scope: ${e.toString()}', originalError: e);
    }
  }

  Future<(String, int)> getFileContent(CloudFileObject file) async {
    try {
      final client = await googleDriveClient;
      
      final fileInfo = await findFileById(file.id);
      if (fileInfo == null) {
        throw GoogleDriveApiException.fileNotFound(file.id);
      }

      final media = await client.files.get(
        fileInfo.id, 
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      if (media is! drive.Media) {
        throw GoogleDriveApiException.invalidResponse();
      }

      final List<int> dataStore = [];
      final completer = Completer<List<int>>();
      
      media.stream.listen(
        (data) => dataStore.addAll(data),
        onDone: () => completer.complete(dataStore),
        onError: (error) => completer.completeError(error),
      );

      final bytes = await completer.future;

      if (file.getFileInfo()?.hasCompression == true) {
        final decodedBytes = io.gzip.decode(bytes);
        return (utf8.decode(decodedBytes), bytes.length);
      } else {
        return (utf8.decode(bytes), bytes.length);
      }
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveApiException.downloadFailed(file.id, e);
    }
  }

  Future<CloudFileListObject> fetchAllBackups(String? nextToken) async {
    try {
      final client = await googleDriveClient;

      final fileList = await client.files.list(
        q: "name contains '.json' or name contains '.zip'",
        spaces: "appDataFolder",
        pageToken: nextToken,
      );

      return CloudFileListObject.fromGoogleDrive(fileList);
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveApiException.listFailed(e);
    }
  }

  Future<CloudFileObject?> findFileById(String fileId) async {
    try {
      final client = await googleDriveClient;

      final file = await client.files.get(fileId);
      if (file is drive.File) {
        return CloudFileObject.fromGoogleDrive(file);
      }

      return null;
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      // File not found is a valid case, don't throw exception
      return null;
    }
  }

  Future<CloudFileObject?> fetchLatestBackup() async {
    try {
      final client = await googleDriveClient;

      final fileList = await client.files.list(
        spaces: "appDataFolder",
        q: "name contains '.json' or name contains '.zip'",
        orderBy: "createdTime desc",
        pageSize: 1,
      );

      if (fileList.files?.firstOrNull == null) return null;
      return CloudFileObject.fromGoogleDrive(fileList.files!.first);
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveApiException.listFailed(e);
    }
  }

  Future<CloudFileObject> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async {
    debugPrint('GoogleDriveClient#uploadFile $fileName');
    
    try {
      final client = await googleDriveClient;

      final fileToUpload = drive.File()
        ..name = fileName
        ..parents = ["appDataFolder"];

      if (folderName != null) {
        final folderId = await loadFolder(client, folderName);
        fileToUpload.parents = [folderId];
      }

      debugPrint('GoogleDriveClient#uploadFile uploading...');
      final received = await client.files.create(
        fileToUpload,
        uploadMedia: drive.Media(
          file.openRead(),
          file.lengthSync(),
        ),
      );

      if (received.id == null) {
        throw GoogleDriveApiException.uploadFailed('No file ID returned');
      }

      debugPrint('GoogleDriveClient#uploadFile uploaded: ${received.id}');
      return CloudFileObject.fromGoogleDrive(received);
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveApiException.uploadFailed(e);
    }
  }

  Future<void> deleteFile(String cloudFileId) async {
    try {
      final client = await googleDriveClient;
      await client.files.delete(cloudFileId);
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveApiException.deleteFailed(cloudFileId, e);
    }
  }

  Future<String> loadFolder(drive.DriveApi client, String folderName) async {
    if (_folderDriveIdByFolderName[folderName] != null) {
      return _folderDriveIdByFolderName[folderName]!;
    }

    try {
      final response = await client.files.list(
        spaces: "appDataFolder",
        q: "name='$folderName' and mimeType='application/vnd.google-apps.folder'",
      );

      if (response.files?.firstOrNull?.id != null) {
        final folderId = response.files!.first.id!;
        debugPrint("Drive folder ${response.files!.first.name} found: $folderId");
        return _folderDriveIdByFolderName[folderName] = folderId;
      }

      final folderToCreate = drive.File()
        ..name = folderName
        ..parents = ["appDataFolder"]
        ..mimeType = "application/vnd.google-apps.folder";

      final createdFolder = await client.files.create(folderToCreate);
      if (createdFolder.id == null) {
        throw GoogleDriveApiException.createFolderFailed(folderName, 'No folder ID returned');
      }
      
      debugPrint("Drive folder ${createdFolder.name} created: ${createdFolder.id}");
      return _folderDriveIdByFolderName[folderName] = createdFolder.id!;
    } catch (e) {
      if (e is GoogleDriveException) rethrow;
      throw GoogleDriveApiException.createFolderFailed(folderName, e);
    }
  }
}
