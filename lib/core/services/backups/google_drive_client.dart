import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
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

// These class are responsible for calling google drive APIs.
// Exception should not catch here. Let repository handle it.
class GoogleDriveClient implements BackupCloudService {
  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

  GoogleUserObject? _currentUser;

  @override
  GoogleUserObject? get currentUser => _currentUser;

  @override
  bool get isSignedIn => _currentUser != null;

  final Map<String, String> _folderDriveIdByFolderName = {};
  final List<String> _requestedScopes = [drive.DriveApi.driveAppdataScope];

  Future<drive.DriveApi?> get googleDriveClient async {
    if (_currentUser == null || _currentUser?.accessToken == null) return null;
    final _GoogleAuthClient client = _GoogleAuthClient(
      _currentUser!.authHeaders,
    );
    return drive.DriveApi(client);
  }

  // load data locally
  @override
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

  @override
  Future<bool> reauthenticateIfNeeded() async {
    await googleServiceInstance; // ensure initialized

    try {
      if (currentUser == null) {
        throw exp.AuthException(
          'No stored user found',
          exp.AuthExceptionType.signInRequired,
          serviceType: serviceType,
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
          accessToken: authHeaders['Authorization']?.replaceFirst(
            'Bearer ',
            '',
          ),
          refreshedAt: DateTime.now(),
        );

        await GoogleUserStorage().writeObject(_currentUser!);
        return true;
      }

      throw exp.AuthException(
        'Failed to get auth headers',
        exp.AuthExceptionType.tokenExpired,
        serviceType: serviceType,
      );
    } on exp.AuthException {
      rethrow;
    } catch (e) {
      throw exp.AuthException(
        'Reauthentication failed: $e',
        exp.AuthExceptionType.signInFailed,
        context: 'reauthenticateIfNeeded',
        serviceType: serviceType,
      );
    }
  }

  @override
  Future<bool> signIn() async {
    try {
      if (!(await googleServiceInstance).supportsAuthenticate()) {
        throw exp.AuthException(
          'Platform does not support authentication',
          exp.AuthExceptionType.signInFailed,
          serviceType: serviceType,
        );
      }

      final account = await (await googleServiceInstance).authenticate(
        scopeHint: _requestedScopes,
      );
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
          serviceType: serviceType,
        );
      }

      throw exp.AuthException(
        'Sign-in failed: $e',
        exp.AuthExceptionType.signInFailed,
        context: 'signIn',
        serviceType: serviceType,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await (await googleServiceInstance).signOut();
    await GoogleUserStorage().remove();
    _currentUser = null;
  }

  @override
  Future<bool> canAccessRequestedScopes() async {
    try {
      if (_currentUser == null || _currentUser!.accessToken == null) {
        throw exp.AuthException(
          'No current user or missing access token',
          exp.AuthExceptionType.signInRequired,
          serviceType: serviceType,
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
        serviceType: serviceType,
      );
    }
  }

  @override
  Future<bool> requestScope() async {
    if (!isSignedIn) return false;

    try {
      final account = await (await googleServiceInstance).authenticate(
        scopeHint: _requestedScopes,
      );
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

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async {
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return null;

    CloudFileObject? fileInfo = await findFileById(file.id);
    if (fileInfo == null) return null;

    Object? media = await client.files.get(
      fileInfo.id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
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

  @override
  Future<CloudFileObject?> findFileById(String fileId) async {
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return null;

    Object file = await client.files.get(fileId);
    if (file is drive.File) return CloudFileObject.fromGoogleDrive(file);

    return null;
  }

  /// Fetch all yearly backups (v3) from the backups/ folder
  /// Returns a map of year -> CloudFileObject
  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async {
    try {
      drive.DriveApi client = await _getAuthenticatedClient();

      // First, ensure backups/ folder exists
      final backupsFolderId = await loadFolder(client, 'backups');

      // No backups folder means no yearly backups yet
      if (backupsFolderId == null) return {};

      drive.FileList fileList = await client.files.list(
        spaces: "appDataFolder",
        q: "name contains 'Backup::3::' and '$backupsFolderId' in parents",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return {};
      }

      Map<int, CloudFileObject> yearlyBackups = {};
      for (var file in fileList.files!) {
        final cloudFile = CloudFileObject.fromGoogleDrive(file);
        final year = cloudFile.year;
        if (year != null) {
          yearlyBackups[year] = cloudFile;
        }
      }

      return yearlyBackups;
    } catch (e) {
      _handleApiException(e, 'fetchYearlyBackups');
      rethrow;
    }
  }

  /// Update an existing yearly backup file atomically using file ID
  /// This prevents race conditions when multiple devices sync simultaneously
  @override
  Future<CloudFileObject?> updateYearlyBackup({
    required String fileId,
    required String fileName,
    required io.File file,
  }) async {
    debugPrint(
      'GoogleDriveService#updateYearlyBackup fileId=$fileId, fileName=$fileName',
    );

    try {
      if (!file.existsSync()) {
        throw exp.FileOperationException(
          'Local file does not exist: ${file.path}',
          exp.FileOperationType.upload,
          context: fileName,
          serviceType: serviceType,
        );
      }

      drive.DriveApi client = await _getAuthenticatedClient();

      // Update both the file content AND the filename (to reflect new timestamp)
      drive.File fileToUpdate = drive.File();
      fileToUpdate.name = fileName;

      debugPrint('GoogleDriveService#updateYearlyBackup uploading...');
      drive.File received = await client.files.update(
        fileToUpdate,
        fileId,
        uploadMedia: drive.Media(
          file.openRead(),
          file.lengthSync(),
        ),
      );

      if (received.id != null) {
        debugPrint(
          'GoogleDriveService#updateYearlyBackup updated: ${received.id}',
        );
        return CloudFileObject.fromGoogleDrive(received);
      }

      throw exp.FileOperationException(
        'Update succeeded but no file ID returned',
        exp.FileOperationType.upload,
        context: fileName,
        serviceType: serviceType,
      );
    } catch (e) {
      _handleApiException(e, 'updateYearlyBackup', context: fileName);
      rethrow;
    }
  }

  /// Upload a new yearly backup file to the backups/ folder
  @override
  Future<CloudFileObject?> uploadYearlyBackup({
    required String fileName,
    required io.File file,
  }) async {
    debugPrint('GoogleDriveService#uploadYearlyBackup $fileName');

    try {
      if (!file.existsSync()) {
        throw exp.FileOperationException(
          'Local file does not exist: ${file.path}',
          exp.FileOperationType.upload,
          context: fileName,
          serviceType: serviceType,
        );
      }

      drive.DriveApi client = await _getAuthenticatedClient();

      // Ensure backups/ folder exists
      String? folderId = await loadFolder(client, 'backups');
      if (folderId == null) {
        throw exp.FileOperationException(
          'Failed to create or find backups folder',
          exp.FileOperationType.upload,
          context: fileName,
          serviceType: serviceType,
        );
      }

      drive.File fileToUpload = drive.File();
      fileToUpload.name = fileName;
      fileToUpload.parents = [folderId];

      debugPrint('GoogleDriveService#uploadYearlyBackup uploading...');
      drive.File received = await client.files.create(
        fileToUpload,
        uploadMedia: drive.Media(
          file.openRead(),
          file.lengthSync(),
        ),
      );

      if (received.id != null) {
        debugPrint(
          'GoogleDriveService#uploadYearlyBackup uploaded: ${received.id}',
        );
        return CloudFileObject.fromGoogleDrive(received);
      }

      throw exp.FileOperationException(
        'Upload succeeded but no file ID returned',
        exp.FileOperationType.upload,
        context: fileName,
        serviceType: serviceType,
      );
    } catch (e) {
      _handleApiException(e, 'uploadYearlyBackup', context: fileName);
      rethrow;
    }
  }

  @override
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
          serviceType: serviceType,
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
            serviceType: serviceType,
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
        serviceType: serviceType,
      );
    } catch (e) {
      _handleApiException(e, 'uploadFile', context: fileName);
      rethrow;
    }
  }

  @override
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
      throw exp.AuthException(
        'Failed to get authenticated Google Drive client',
        exp.AuthExceptionType.signInRequired,
        serviceType: serviceType,
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
        serviceType: serviceType,
      );
    }

    if (error.toString().contains('403')) {
      if (error.toString().toLowerCase().contains('quota') || error.toString().toLowerCase().contains('limit')) {
        throw exp.QuotaException(
          'Quota exceeded during $operation',
          exp.QuotaExceptionType.rateLimitExceeded,
          context: context,
          serviceType: serviceType,
        );
      }
      throw exp.AuthException(
        'Access denied during $operation',
        exp.AuthExceptionType.tokenRevoked,
        context: context,
        serviceType: serviceType,
      );
    }

    if (error.toString().contains('404')) {
      throw exp.FileOperationException(
        'File not found during $operation',
        _getFileOperationType(operation),
        context: context,
        serviceType: serviceType,
      );
    }

    if (error.toString().contains('429')) {
      throw exp.QuotaException(
        'Rate limit exceeded during $operation',
        exp.QuotaExceptionType.rateLimitExceeded,
        context: context,
        serviceType: serviceType,
      );
    }

    // Handle network errors
    if (error is io.SocketException || error is TimeoutException) {
      throw exp.NetworkException(
        'Network error during $operation: $error',
        context: context,
        serviceType: serviceType,
      );
    }

    // Default to service exception for unknown errors
    throw exp.ServiceException(
      'Unknown error during $operation: $error',
      exp.ServiceExceptionType.unexpectedError,
      context: context,
      serviceType: serviceType,
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
      debugPrint(
        "Drive folder ${response.files!.first.name} founded: ${response.files!.first.id}",
      );
      return _folderDriveIdByFolderName[folderName] = response.files!.first.id!;
    }

    drive.File folderToCreate = drive.File();
    folderToCreate.name = folderName;
    folderToCreate.parents = ["appDataFolder"];
    folderToCreate.mimeType = "application/vnd.google-apps.folder";

    final createdFolder = await client.files.create(folderToCreate);
    debugPrint(
      "Drive folder ${createdFolder.name} created: ${createdFolder.id}",
    );

    return _folderDriveIdByFolderName[folderName] = createdFolder.id!;
  }
}
