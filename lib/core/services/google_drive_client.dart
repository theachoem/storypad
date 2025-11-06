import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
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

// These class aren responsible for call google drive APIs.
// Exception should not catch here. Let repository handle it.
class GoogleDriveClient {
  GoogleUserObject? _currentUser;
  GoogleUserObject? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  final Map<String, String> _folderDriveIdByFolderName = {};
  final List<String> _requestedScopes = [drive.DriveApi.driveAppdataScope];

  Future<drive.DriveApi?> get googleDriveClient async {
    if (_currentUser == null || _currentUser?.accessToken == null) return null;
    final _GoogleAuthClient client = _GoogleAuthClient(_currentUser!.authHeaders);
    return drive.DriveApi(client);
  }

  // load data locally
  Future<void> initialize() async {
    _currentUser = await GoogleUserStorage().readObject();
  }

  Completer<gsi.GoogleSignIn>? googleServiceCompleter;
  Future<gsi.GoogleSignIn> get googleServiceInstance async {
    if (googleServiceCompleter != null) return googleServiceCompleter!.future;
    googleServiceCompleter = Completer<gsi.GoogleSignIn>();

    try {
      await gsi.GoogleSignIn.instance.initialize();
      googleServiceCompleter!.complete(gsi.GoogleSignIn.instance);
    } catch (e) {
      googleServiceCompleter!.completeError(e);
      googleServiceCompleter = null;
    }

    return googleServiceCompleter!.future;
  }

  Future<bool> reauthenticateIfNeeded() async {
    await googleServiceInstance; // ensure initialized

    try {
      if (currentUser == null) {
        throw const exp.AuthException(
          'No stored user found',
          exp.AuthExceptionType.signInRequired,
        );
      }

      final authHeaders = await (await googleServiceInstance).authorizationClient.authorizationHeaders(
        _requestedScopes,
        promptIfNecessary: true,
      );

      if (authHeaders != null) {
        _currentUser = GoogleUserObject(
          id: _currentUser!.id,
          email: _currentUser!.email,
          displayName: _currentUser!.displayName,
          photoUrl: _currentUser!.photoUrl,
          accessToken: authHeaders['Authorization']?.replaceFirst('Bearer ', ''),
          refreshedAt: DateTime.now(),
        );

        await GoogleUserStorage().writeObject(_currentUser!);
        return true;
      }

      throw const exp.AuthException(
        'Failed to get auth headers',
        exp.AuthExceptionType.tokenExpired,
      );
    } on exp.AuthException {
      rethrow;
    } catch (e) {
      throw exp.AuthException(
        'Reauthentication failed: $e',
        exp.AuthExceptionType.signInFailed,
        context: 'reauthenticateIfNeeded',
      );
    }
  }

  Future<bool> signIn() async {
    try {
      if (!(await googleServiceInstance).supportsAuthenticate()) {
        throw const exp.AuthException(
          'Platform does not support authentication',
          exp.AuthExceptionType.signInFailed,
        );
      }

      final account = await (await googleServiceInstance).authenticate(scopeHint: _requestedScopes);
      final authHeaders = await account.authorizationClient.authorizationHeaders(
        _requestedScopes,
        promptIfNecessary: true,
      );

      _currentUser = GoogleUserObject(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: authHeaders?['Authorization']?.replaceFirst('Bearer ', ''),
        refreshedAt: DateTime.now(),
      );

      await GoogleUserStorage().writeObject(_currentUser!);
      return true;
    } catch (e) {
      if (e is exp.AuthException) rethrow;

      if (e is gsi.GoogleSignInException) {
        throw exp.AuthException(
          e.description ?? e.toString(),
          exp.AuthExceptionType.signInRequired,
          context: 'signIn',
        );
      }

      throw exp.AuthException(
        'Sign-in failed: $e',
        exp.AuthExceptionType.signInFailed,
        context: 'signIn',
      );
    }
  }

  Future<void> signOut() async {
    await (await googleServiceInstance).signOut();
    await GoogleUserStorage().remove();
    _currentUser = null;
  }

  Future<bool> canAccessRequestedScopes() async {
    try {
      if (_currentUser == null || _currentUser!.accessToken == null) {
        throw const exp.AuthException(
          'No current user or missing access token',
          exp.AuthExceptionType.signInRequired,
        );
      }

      // If we have a non-null access token and it was recently refreshed, we have the scopes
      // Google's authenticate() method requests all necessary scopes upfront
      return _currentUser!.isRefreshedRecently();
    } on exp.AuthException {
      rethrow;
    } catch (e) {
      throw exp.AuthException(
        'Scope validation failed: $e',
        exp.AuthExceptionType.signInFailed,
        context: 'canAccessRequestedScopes',
      );
    }
  }

  Future<bool> requestScope() async {
    if (!isSignedIn) return false;

    try {
      final account = await (await googleServiceInstance).authenticate(scopeHint: _requestedScopes);
      final authHeaders = await account.authorizationClient.authorizationHeaders(
        _requestedScopes,
        promptIfNecessary: true,
      );

      if (authHeaders == null) {
        await (await googleServiceInstance).disconnect();
        _currentUser = null;
        await GoogleUserStorage().remove();
        return false;
      }

      _currentUser = GoogleUserObject(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: authHeaders['Authorization']?.replaceFirst('Bearer ', ''),
        refreshedAt: DateTime.now(),
      );

      await GoogleUserStorage().writeObject(_currentUser!);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<(String, int)?> getFileContent(CloudFileObject file) async {
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return null;

    CloudFileObject? fileInfo = await findFileById(file.id);
    if (fileInfo == null) return null;

    Object? media = await client.files.get(fileInfo.id, downloadOptions: drive.DownloadOptions.fullMedia);
    if (media is! drive.Media) return null;

    if (file.getFileInfo()?.hasCompression == true) {
      List<int> dataStore = [];

      final completer = Completer<List<int>>();
      media.stream.listen(
        (data) => dataStore.insertAll(dataStore.length, data),
        onDone: () => completer.complete(dataStore),
        onError: (error) => completer.completeError(error),
      );

      final bytes = await completer.future;
      final decodedBytes = io.gzip.decode(bytes);
      return (utf8.decode(decodedBytes), bytes.length);
    } else {
      List<int> dataStore = [];

      Completer completer = Completer();
      media.stream.listen(
        (data) => dataStore.insertAll(dataStore.length, data),
        onDone: () => completer.complete(utf8.decode(dataStore)),
        onError: (error) {},
      );

      await completer.future;
      return (utf8.decode(dataStore), dataStore.length);
    }
  }

  Future<CloudFileListObject?> fetchAllBackups(String? nextToken) async {
    try {
      drive.DriveApi client = await _getAuthenticatedClient();

      drive.FileList fileList = await client.files.list(
        q: "name contains '.json' or name contains '.zip'",
        spaces: "appDataFolder",
        pageToken: nextToken,
      );

      return CloudFileListObject.fromGoogleDrive(fileList);
    } catch (e) {
      _handleApiException(e, 'fetchAllBackups');
      rethrow;
    }
  }

  Future<CloudFileObject?> findFileById(String fileId) async {
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return null;

    Object file = await client.files.get(fileId);
    if (file is drive.File) return CloudFileObject.fromGoogleDrive(file);

    return null;
  }

  Future<CloudFileObject?> fetchLatestBackup() async {
    try {
      drive.DriveApi? client = await _getAuthenticatedClient();

      drive.FileList fileList = await client.files.list(
        spaces: "appDataFolder",
        q: "name contains '.json' or name contains '.zip'",
        orderBy: "createdTime desc",
        pageSize: 1,
      );

      if (fileList.files?.firstOrNull == null) return null;
      return CloudFileObject.fromGoogleDrive(fileList.files!.first);
    } catch (e) {
      _handleApiException(e, 'fetchLatestBackup');
      rethrow;
    }
  }

  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async {
    debugPrint('GoogleDriveService#uploadFile $fileName');

    try {
      if (!file.existsSync()) {
        throw exp.FileOperationException(
          'Local file does not exist: ${file.path}',
          exp.FileOperationType.upload,
          context: fileName,
        );
      }

      drive.DriveApi client = await _getAuthenticatedClient();

      drive.File fileToUpload = drive.File();
      fileToUpload.name = fileName;
      fileToUpload.parents = ["appDataFolder"];

      if (folderName != null) {
        String? folderId = await loadFolder(client, folderName);
        if (folderId == null) {
          throw exp.FileOperationException(
            'Failed to create or find folder: $folderName',
            exp.FileOperationType.upload,
            context: fileName,
          );
        }
        fileToUpload.parents = [folderId];
      }

      debugPrint('GoogleDriveService#uploadFile uploading...');
      drive.File received = await client.files.create(
        fileToUpload,
        uploadMedia: drive.Media(
          file.openRead(),
          file.lengthSync(),
        ),
      );

      if (received.id != null) {
        debugPrint('GoogleDriveService#uploadFile uploaded: ${received.id}');
        return CloudFileObject.fromGoogleDrive(received);
      }

      throw exp.FileOperationException(
        'Upload succeeded but no file ID returned',
        exp.FileOperationType.upload,
        context: fileName,
      );
    } catch (e) {
      _handleApiException(e, 'uploadFile', context: fileName);
      rethrow;
    }
  }

  Future<bool> deleteFile(String cloudFileId) async {
    try {
      drive.DriveApi client = await _getAuthenticatedClient();
      await client.files.delete(cloudFileId);
      return true;
    } catch (e) {
      _handleApiException(e, 'deleteFile', context: cloudFileId);
      rethrow;
    }
  }

  /// Get authenticated Drive API client or throw appropriate exception
  Future<drive.DriveApi> _getAuthenticatedClient() async {
    final client = await googleDriveClient;
    if (client == null) {
      throw const exp.AuthException(
        'Failed to get authenticated Google Drive client',
        exp.AuthExceptionType.signInRequired,
      );
    }
    return client;
  }

  /// Handle and map API exceptions to appropriate BackupExceptions
  void _handleApiException(dynamic error, String operation, {String? context}) {
    if (error is exp.BackupException) return; // Already a BackupException

    // Handle specific HTTP errors from Google APIs
    if (error.toString().contains('401')) {
      throw exp.AuthException(
        'Authentication failed during $operation',
        exp.AuthExceptionType.tokenExpired,
        context: context,
      );
    }

    if (error.toString().contains('403')) {
      if (error.toString().toLowerCase().contains('quota') || error.toString().toLowerCase().contains('limit')) {
        throw exp.QuotaException(
          'Quota exceeded during $operation',
          exp.QuotaExceptionType.rateLimitExceeded,
          context: context,
        );
      }
      throw exp.AuthException(
        'Access denied during $operation',
        exp.AuthExceptionType.tokenRevoked,
        context: context,
      );
    }

    if (error.toString().contains('404')) {
      throw exp.FileOperationException(
        'File not found during $operation',
        _getFileOperationType(operation),
        context: context,
      );
    }

    if (error.toString().contains('429')) {
      throw exp.QuotaException(
        'Rate limit exceeded during $operation',
        exp.QuotaExceptionType.rateLimitExceeded,
        context: context,
      );
    }

    // Handle network errors
    if (error is io.SocketException || error is TimeoutException) {
      throw exp.NetworkException(
        'Network error during $operation: $error',
        context: context,
      );
    }

    // Default to service exception for unknown errors
    throw exp.ServiceException(
      'Unknown error during $operation: $error',
      exp.ServiceExceptionType.unexpectedError,
      context: context,
    );
  }

  /// Map operation name to exp.FileOperationType
  exp.FileOperationType _getFileOperationType(String operation) {
    switch (operation.toLowerCase()) {
      case 'uploadfile':
      case 'upload':
        return exp.FileOperationType.upload;
      case 'deletefile':
      case 'delete':
        return exp.FileOperationType.delete;
      case 'downloadfile':
      case 'download':
        return exp.FileOperationType.download;
      default:
        return exp.FileOperationType.list;
    }
  }

  Future<String?> loadFolder(drive.DriveApi client, String folderName) async {
    if (_folderDriveIdByFolderName[folderName] != null) return _folderDriveIdByFolderName[folderName];

    drive.FileList response = await client.files.list(
      spaces: "appDataFolder",
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder'",
    );

    if (response.files?.firstOrNull?.id != null) {
      debugPrint("Drive folder ${response.files!.first.name} founded: ${response.files!.first.id}");
      return _folderDriveIdByFolderName[folderName] = response.files!.first.id!;
    }

    drive.File folderToCreate = drive.File();
    folderToCreate.name = folderName;
    folderToCreate.parents = ["appDataFolder"];
    folderToCreate.mimeType = "application/vnd.google-apps.folder";

    final createdFolder = await client.files.create(folderToCreate);
    debugPrint("Drive folder ${createdFolder.name} created: ${createdFolder.id}");

    return _folderDriveIdByFolderName[folderName] = createdFolder.id!;
  }
}
