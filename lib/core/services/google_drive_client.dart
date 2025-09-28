import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  final GoogleSignIn googleSignIn = GoogleSignIn.standard(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  Future<drive.DriveApi?> get googleDriveClient async {
    if (googleSignIn.currentUser == null) return null;
    final _GoogleAuthClient client = _GoogleAuthClient(await googleSignIn.currentUser!.authHeaders);
    return drive.DriveApi(client);
  }

  Future<void> loadUserLocally() async {
    _currentUser = await GoogleUserStorage().readObject();
  }

  Future<bool> reauthenticateIfNeeded() async {
    try {
      _currentUser = await GoogleUserStorage().readObject();
      if (currentUser == null) {
        throw const exp.AuthException(
          'No stored user found',
          exp.AuthExceptionType.signInRequired,
        );
      }

      if (!await googleSignIn.isSignedIn()) {
        _currentUser = null;
        await GoogleUserStorage().remove();
        throw const exp.AuthException(
          'Not signed in to Google',
          exp.AuthExceptionType.signInRequired,
        );
      }

      final account = await googleSignIn.signInSilently(
        reAuthenticate: currentUser == null || !currentUser!.isRefreshedRecently(),
        suppressErrors: false,
      );

      if (account != null) {
        _currentUser = GoogleUserObject(
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          accessToken: await account.authentication.then((e) => e.accessToken),
          refreshedAt: DateTime.now(),
        );

        await GoogleUserStorage().writeObject(_currentUser!);
        return true;
      }

      throw const exp.AuthException(
        'Silent sign-in failed',
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
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw const exp.AuthException(
          'Sign-in was cancelled by user',
          exp.AuthExceptionType.signInFailed,
        );
      }

      final authentication = await account.authentication;
      if (authentication.accessToken == null) {
        throw const exp.AuthException(
          'Failed to obtain access token',
          exp.AuthExceptionType.signInFailed,
        );
      }

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
      if (e is exp.AuthException) rethrow;

      throw exp.AuthException(
        'Sign-in failed: $e',
        exp.AuthExceptionType.signInFailed,
        context: 'signIn',
      );
    }
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await GoogleUserStorage().remove();
    _currentUser = null;
  }

  Future<bool> canAccessRequestedScopes() async {
    try {
      final user = googleSignIn.currentUser;
      if (user == null) {
        throw const exp.AuthException(
          'No current user',
          exp.AuthExceptionType.signInRequired,
        );
      }

      final authentication = await user.authentication;
      final accessToken = authentication.accessToken;
      if (accessToken == null) {
        throw const exp.AuthException(
          'No access token available',
          exp.AuthExceptionType.tokenExpired,
        );
      }

      String? accessedScopes;
      try {
        http.Response response = await http
            .get(
              Uri.parse('https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=$accessToken'),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 401) {
          throw const exp.AuthException(
            'Access token is invalid or expired',
            exp.AuthExceptionType.tokenExpired,
          );
        }

        if (response.statusCode == 403) {
          throw const exp.AuthException(
            'Access token has been revoked',
            exp.AuthExceptionType.tokenRevoked,
          );
        }

        if (response.statusCode != 200) {
          throw exp.NetworkException(
            'Failed to validate token: HTTP ${response.statusCode}',
            context: 'token validation',
          );
        }

        final Map<String, dynamic> tokenInfo = json.decode(response.body);
        accessedScopes = tokenInfo['scope'] as String?;
      } on io.SocketException catch (e) {
        throw exp.NetworkException(
          'Network error during token validation: $e',
          context: 'canAccessRequestedScopes',
        );
      } on TimeoutException catch (e) {
        throw exp.NetworkException(
          'Timeout during token validation: $e',
          context: 'canAccessRequestedScopes',
        );
      }

      final hasRequiredScopes = googleSignIn.scopes.every((requestedScope) {
        return accessedScopes?.contains(requestedScope) ?? false;
      });

      if (!hasRequiredScopes) {
        throw const exp.AuthException(
          'Insufficient scopes granted',
          exp.AuthExceptionType.insufficientScopes,
        );
      }

      return true;
    } on exp.AuthException {
      rethrow;
    } on exp.NetworkException {
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

    bool requested = await googleSignIn.requestScopes(googleSignIn.scopes);
    bool authorized = await canAccessRequestedScopes();

    // in case we request scope success but still unauthorize, it mean user can disconnect app from Google app directly.
    if (requested && !authorized) {
      await googleSignIn.disconnect();
      _currentUser = null;
      await GoogleUserStorage().remove();
    }

    // after request, access token might be renew.
    final account = googleSignIn.currentUser;
    if (authorized && account != null) {
      _currentUser = GoogleUserObject(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: await account.authentication.then((e) => e.accessToken),
        refreshedAt: DateTime.now(),
      );
      await GoogleUserStorage().writeObject(_currentUser!);
    }

    return authorized;
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
