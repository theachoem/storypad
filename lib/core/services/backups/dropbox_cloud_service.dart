import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/objects/dropbox_user_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/dropbox_oauth_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/dropbox_user_storage.dart';

/// Thrown for any non-2xx Dropbox API response — classified into a typed
/// [exp.BackupException] by [DropboxCloudService._buildException]. Dropbox
/// reports most errors as HTTP 409 with a structured JSON body rather than
/// distinct status codes per error kind, so the body has to be inspected too.
class _DropboxApiException implements Exception {
  final int statusCode;
  final String body;
  _DropboxApiException(this.statusCode, this.body);

  @override
  String toString() => 'DropboxApiException($statusCode): $body';
}

/// Dropbox backup target — plain REST over `api.dropboxapi.com` /
/// `content.dropboxapi.com`, no SDK (Dropbox doesn't publish one for Dart).
///
/// Runs entirely client-side: [DropboxOAuthService] performs the OAuth2 PKCE
/// flow for public/native clients, so there's no client secret anywhere and
/// no backend involved (see docs/app/architecture/backup-sync.md). The app
/// requests **App folder** access — every path here is already relative to
/// the app's sandboxed `Apps/StoryPad` folder, so unlike Nextcloud there's no
/// customizable root folder to thread through.
///
/// Two things make this closer to Drive than to Nextcloud/iCloud:
/// - Dropbox assigns real stable file IDs (`id:xxxx`) independent of path, so
///   [CloudFileObject.id] is that ID, not a path.
/// - `files/delete_v2` already soft-deletes into Dropbox's own native trash —
///   no manual `.trash/`-folder emulation is needed. Restoring a deleted file
///   is done by finding its most recent revision (`files/list_revisions`,
///   since deleted-file metadata carries no `rev`) and restoring that
///   revision's path (`files/restore`) — Dropbox has no separate "undelete".
class DropboxCloudService extends BackupCloudService {
  final DropboxOAuthService _oauth = DropboxOAuthService();

  @override
  BackupServiceType get serviceType => BackupServiceType.dropbox;

  DropboxUserObject? _currentUser;

  @override
  DropboxUserObject? get currentUser => _currentUser;

  @override
  bool get isSignedIn => _currentUser != null;

  @override
  Future<void> initialize() async {
    _currentUser = await DropboxUserStorage().readObject();
  }

  @override
  void setAutoBackupEnabled(bool enabled) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(autoBackupEnabled: enabled);
    DropboxUserStorage().writeObject(_currentUser!);
  }

  @override
  Future<bool> signIn() async {
    try {
      final tokens = await _oauth.authenticate();
      final refreshToken = tokens.refreshToken;
      if (refreshToken == null) {
        throw exp.AuthException(
          'Dropbox did not return a refresh token (token_access_type=offline missing?)',
          exp.AuthExceptionType.signInFailed,
          context: 'signIn',
          serviceType: serviceType,
        );
      }

      final account = await _fetchAccount(accessToken: tokens.accessToken);

      _currentUser = DropboxUserObject(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: tokens.accessToken,
        refreshToken: refreshToken,
        accessTokenExpiresAt: tokens.expiresAt,
        autoBackupEnabled: autoBackupEnabled,
      );

      await DropboxUserStorage().writeObject(_currentUser!);
      return true;
    } catch (e) {
      if (e is exp.AuthException) rethrow;
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
    await DropboxUserStorage().remove();
    _currentUser = null;
  }

  @override
  Future<bool> reauthenticateIfNeeded() async {
    final user = _currentUser;
    if (user == null) {
      throw exp.AuthException(
        'No stored user found',
        exp.AuthExceptionType.signInRequired,
        serviceType: serviceType,
      );
    }

    if (!user.accessTokenExpiredOrExpiringSoon) return true;

    final refreshed = await _oauth.refresh(refreshToken: user.refreshToken);
    if (refreshed == null) {
      throw exp.AuthException(
        'Dropbox refresh token was revoked',
        exp.AuthExceptionType.tokenRevoked,
        context: 'reauthenticateIfNeeded',
        serviceType: serviceType,
      );
    }

    _currentUser = user.copyWith(
      accessToken: refreshed.accessToken,
      refreshToken: refreshed.refreshToken ?? user.refreshToken,
      accessTokenExpiresAt: refreshed.expiresAt,
    );
    await DropboxUserStorage().writeObject(_currentUser!);
    return true;
  }

  /// Dropbox's permission scopes are fixed at consent time in the app
  /// console, not requested incrementally at runtime like Drive's — so
  /// there's nothing to actually check beyond being signed in at all.
  @override
  Future<bool> canAccessRequestedScopes() async => isSignedIn;

  @override
  Future<bool> requestScope() async => isSignedIn;

  ({String id, String email, String? displayName, String? photoUrl}) _parseAccount(Map<String, dynamic> body) {
    final name = body['name'] as Map<String, dynamic>?;
    return (
      id: body['account_id'] as String,
      email: body['email'] as String,
      displayName: name?['display_name'] as String?,
      photoUrl: body['profile_photo_url'] as String?,
    );
  }

  Future<({String id, String email, String? displayName, String? photoUrl})> _fetchAccount({
    required String accessToken,
  }) async {
    final response = await http.post(
      _apiUri('users/get_current_account'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw exp.AuthException(
        'Failed to fetch Dropbox account: ${response.body}',
        exp.AuthExceptionType.signInFailed,
        context: 'signIn',
        serviceType: serviceType,
      );
    }

    return _parseAccount(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Uri _apiUri(String endpoint) => Uri.parse('https://api.dropboxapi.com/2/$endpoint');
  Uri _contentUri(String endpoint) => Uri.parse('https://content.dropboxapi.com/2/$endpoint');

  Map<String, String> get _authHeader {
    final user = _currentUser;
    if (user == null) {
      throw exp.AuthException(
        'Failed to get authenticated Dropbox client',
        exp.AuthExceptionType.signInRequired,
        serviceType: serviceType,
      );
    }
    return {'Authorization': 'Bearer ${user.accessToken}'};
  }

  Future<http.Response> _postJson(Uri uri, Map<String, dynamic> body) {
    return http.post(
      uri,
      headers: {..._authHeader, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw _DropboxApiException(response.statusCode, response.body);
  }

  /// Dropbox reports most "no such file" conditions as HTTP 409, but 409 also
  /// covers many *other*, distinct structured errors (`restricted_content`,
  /// `malformed_path`, ...) — treating every 409 as "not found" would
  /// silently swallow those into a missing backup instead of surfacing them.
  /// `error_summary` is a stable, always-present plain string Dropbox
  /// includes on every structured error response, so it's checked instead of
  /// just the status code.
  bool _isPathNotFound(http.Response response) {
    if (response.statusCode != 409) return false;
    return _errorSummary(response.body)?.startsWith('path/not_found') == true;
  }

  String? _errorSummary(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error_summary'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _filePath(String fileName, {String? folderName}) =>
      folderName != null ? '/$folderName/$fileName' : '/$fileName';

  String _parentPath(String path) {
    final index = path.lastIndexOf('/');
    return index <= 0 ? '' : path.substring(0, index);
  }

  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async {
    return _executeWithRetry(
      methodName: 'fetchYearlyBackups',
      operation: () async {
        final files = await _listFolder('/backups', swallow404: true);

        final Map<int, CloudFileObject> yearlyBackups = {};
        for (final file in files) {
          final cloudFile = CloudFileObject.fromDropbox(file);
          final year = cloudFile.year;
          if (year == null) continue;

          final existing = yearlyBackups[year];
          final existingTs = existing?.lastUpdatedAt;
          final newTs = cloudFile.lastUpdatedAt;
          final isNewer = existing == null || (newTs != null && (existingTs == null || newTs.isAfter(existingTs)));
          if (isNewer) yearlyBackups[year] = cloudFile;
        }

        return yearlyBackups;
      },
    );
  }

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async {
    return _executeWithRetry(
      methodName: 'getFileContent',
      operation: () async {
        final bytes = await _downloadBytes(file.id, swallow404: true);
        if (bytes == null) return null;

        if (file.getFileInfo()?.hasCompression == true) {
          final decoded = io.gzip.decode(bytes);
          return (utf8.decode(decoded), bytes.length);
        }

        return (utf8.decode(bytes), bytes.length);
      },
    );
  }

  @override
  Future<List<int>?> downloadFileBytes(String fileId) async {
    return _executeWithRetry(
      methodName: 'downloadFileBytes',
      // Unlike getFileContent above, a not-found here must surface as a
      // FileOperationException (via _buildException) rather than null — see
      // BackupCloudService.downloadFileBytes's contract.
      operation: () => _downloadBytes(fileId, swallow404: false),
    );
  }

  Future<List<int>?> _downloadBytes(String fileIdOrPath, {required bool swallow404}) async {
    final response = await http.post(
      _contentUri('files/download'),
      headers: {
        ..._authHeader,
        'Dropbox-API-Arg': jsonEncode({'path': fileIdOrPath}),
      },
    );

    if (swallow404 && _isPathNotFound(response)) return null;
    _throwIfError(response);
    return response.bodyBytes;
  }

  @override
  Future<CloudFileObject?> findFileById(String fileId) async {
    return _executeWithRetry(
      methodName: 'findFileById',
      operation: () async {
        final response = await _postJson(_apiUri('files/get_metadata'), {'path': fileId});
        if (_isPathNotFound(response)) return null;
        _throwIfError(response);

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['.tag'] != 'file') return null;
        return CloudFileObject.fromDropbox(body);
      },
    );
  }

  @override
  Future<CloudFileObject?> findFileByIdIncludingTrashed(String fileId) async {
    return _executeWithRetry(
      methodName: 'findFileByIdIncludingTrashed',
      operation: () async {
        final response = await _postJson(_apiUri('files/get_metadata'), {
          'path': fileId,
          'include_deleted': true,
        });
        if (_isPathNotFound(response)) return null;
        _throwIfError(response);

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final trashed = body['.tag'] == 'deleted';
        return CloudFileObject.fromDropbox(body, trashed: trashed, idOverride: trashed ? fileId : null);
      },
    );
  }

  @override
  Future<bool> deleteFile(String cloudFileId) async {
    return _executeWithRetry(
      methodName: 'deleteFile',
      operation: () async {
        final response = await _postJson(_apiUri('files/delete_v2'), {'path': cloudFileId});
        _throwIfError(response);
        return true;
      },
    );
  }

  /// Dropbox's [deleteFile] already soft-deletes into its own native trash —
  /// there's no separate "move to trash" call the way WebDAV/iCloud need.
  @override
  Future<bool> trashFile(String cloudFileId) => deleteFile(cloudFileId);

  @override
  Future<bool> restoreFileFromTrash(String cloudFileId) async {
    return _executeWithRetry(
      methodName: 'restoreFileFromTrash',
      operation: () async {
        final metadataResponse = await _postJson(_apiUri('files/get_metadata'), {
          'path': cloudFileId,
          'include_deleted': true,
        });
        _throwIfError(metadataResponse);
        final metadata = jsonDecode(metadataResponse.body) as Map<String, dynamic>;
        final path = metadata['path_lower'] as String;

        // Deleted-file metadata carries no `rev` (only live FileMetadata
        // does), so the path's most recent revision has to be looked up
        // first — restoring that revision's path is Dropbox's documented way
        // to undelete a file; there's no separate "undelete" endpoint.
        final revisionsResponse = await _postJson(_apiUri('files/list_revisions'), {
          'path': path,
          'mode': 'path',
          'limit': 1,
        });
        _throwIfError(revisionsResponse);
        final revisions = jsonDecode(revisionsResponse.body) as Map<String, dynamic>;
        final entries = (revisions['entries'] as List).cast<Map<String, dynamic>>();
        if (entries.isEmpty) {
          throw exp.FileOperationException(
            'No revisions found to restore',
            exp.FileOperationType.delete,
            context: cloudFileId,
            serviceType: serviceType,
          );
        }

        final rev = entries.first['rev'] as String;
        final restoreResponse = await _postJson(_apiUri('files/restore'), {'path': path, 'rev': rev});
        _throwIfError(restoreResponse);
        return true;
      },
    );
  }

  @override
  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async {
    return _executeWithRetry(
      methodName: 'uploadFile',
      operation: () async {
        if (!file.existsSync()) {
          throw exp.FileOperationException(
            'Local file does not exist: ${file.path}',
            exp.FileOperationType.upload,
            context: fileName,
            serviceType: serviceType,
          );
        }

        final path = _filePath(fileName, folderName: folderName);
        final bytes = await file.readAsBytes();

        final response = await http.post(
          _contentUri('files/upload'),
          headers: {
            ..._authHeader,
            'Dropbox-API-Arg': jsonEncode({'path': path, 'mode': 'overwrite', 'mute': true}),
            'Content-Type': 'application/octet-stream',
          },
          body: bytes,
        );
        _throwIfError(response);

        return CloudFileObject.fromDropbox(jsonDecode(response.body) as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<CloudFileObject?> updateFile({
    required String fileId,
    required String fileName,
    required io.File file,
  }) async {
    return _executeWithRetry(
      methodName: 'updateFile',
      operation: () async {
        if (!file.existsSync()) {
          throw exp.FileOperationException(
            'Local file does not exist: ${file.path}',
            exp.FileOperationType.upload,
            context: fileName,
            serviceType: serviceType,
          );
        }

        // Yearly backup filenames embed a timestamp, so an "update" writes a
        // new path in the same folder — the old file's own path has to be
        // looked up from its ID first (Dropbox content endpoints take a
        // path, not a bare ID).
        final oldMetadataResponse = await _postJson(_apiUri('files/get_metadata'), {'path': fileId});
        _throwIfError(oldMetadataResponse);
        final oldPath = (jsonDecode(oldMetadataResponse.body) as Map<String, dynamic>)['path_lower'] as String;
        final folder = _parentPath(oldPath);
        final newPath = folder.isEmpty ? '/$fileName' : '$folder/$fileName';

        final bytes = await file.readAsBytes();
        final uploadResponse = await http.post(
          _contentUri('files/upload'),
          headers: {
            ..._authHeader,
            'Dropbox-API-Arg': jsonEncode({'path': newPath, 'mode': 'overwrite', 'mute': true}),
            'Content-Type': 'application/octet-stream',
          },
          body: bytes,
        );
        _throwIfError(uploadResponse);
        final uploaded = jsonDecode(uploadResponse.body) as Map<String, dynamic>;

        if (newPath.toLowerCase() != oldPath) {
          try {
            final deleteResponse = await _postJson(_apiUri('files/delete_v2'), {'path': fileId});
            _throwIfError(deleteResponse);
          } catch (e) {
            AppLogger.d('DropboxCloudService#updateFile: failed to remove old file $fileId: $e');
          }
        }

        return CloudFileObject.fromDropbox(uploaded);
      },
    );
  }

  @override
  Future<List<CloudFileObject>> listFilesInFolder(String folderName) async {
    return _executeWithRetry(
      methodName: 'listFilesInFolder',
      operation: () async {
        final files = await _listFolder('/$folderName', swallow404: true);
        return files.map((file) => CloudFileObject.fromDropbox(file)).toList();
      },
    );
  }

  /// [folderPath] must be `''` for the app-folder root (Dropbox's own
  /// convention — `'/'` is rejected), or `/name` otherwise. Handles
  /// `list_folder`/`list_folder/continue` pagination internally.
  Future<List<Map<String, dynamic>>> _listFolder(
    String folderPath, {
    bool swallow404 = false,
    bool recursive = false,
  }) async {
    var response = await _postJson(_apiUri('files/list_folder'), {'path': folderPath, 'recursive': recursive});

    if (swallow404 && _isPathNotFound(response)) return [];
    _throwIfError(response);

    final entries = <Map<String, dynamic>>[];
    var body = jsonDecode(response.body) as Map<String, dynamic>;
    entries.addAll((body['entries'] as List).cast<Map<String, dynamic>>());

    while (body['has_more'] == true) {
      response = await _postJson(_apiUri('files/list_folder/continue'), {'cursor': body['cursor']});
      _throwIfError(response);
      body = jsonDecode(response.body) as Map<String, dynamic>;
      entries.addAll((body['entries'] as List).cast<Map<String, dynamic>>());
    }

    return entries.where((entry) => entry['.tag'] == 'file').toList();
  }

  @override
  Future<CloudStorageQuotaObject?> fetchStorageQuota() async {
    if (_currentUser == null) return null;

    try {
      final files = await _listFolder('', swallow404: true, recursive: true);
      final appUsage = files.fold<int>(0, (total, file) => total + ((file['size'] as int?) ?? 0));

      final spaceResponse = await _postJson(_apiUri('users/get_space_usage'), {});
      _throwIfError(spaceResponse);
      final space = jsonDecode(spaceResponse.body) as Map<String, dynamic>;
      final allocation = space['allocation'] as Map<String, dynamic>?;

      return CloudStorageQuotaObject(
        appUsageInBytes: appUsage,
        accountUsageInBytes: space['used'] as int?,
        limitInBytes: allocation?['allocated'] as int?,
      );
    } catch (e, s) {
      AppLogger.error('DropboxCloudService#fetchStorageQuota failed: $e', stackTrace: s);
      return null;
    }
  }

  Future<T> _executeWithRetry<T>({
    required String methodName,
    required Future<T> Function() operation,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final exception = _buildException(e, methodName);

      if (exception is exp.AuthException && exception.requiresReauth) {
        final reauthenticated = await reauthenticateIfNeeded();

        if (reauthenticated) {
          try {
            return await operation();
          } catch (e) {
            throw _buildException(e, methodName);
          }
        }
      }

      throw exception;
    }
  }

  exp.BackupException _buildException(dynamic error, String methodName) {
    if (error is exp.BackupException) return error;

    if (error is _DropboxApiException) {
      if (error.statusCode == 401) {
        return exp.AuthException(
          'Authentication failed during $methodName',
          exp.AuthExceptionType.tokenExpired,
          context: methodName,
          serviceType: serviceType,
        );
      }

      if (error.statusCode == 429) {
        return exp.QuotaException(
          'Rate limit exceeded during $methodName',
          exp.QuotaExceptionType.rateLimitExceeded,
          context: methodName,
          serviceType: serviceType,
        );
      }

      if (error.statusCode == 409) {
        final summary = _errorSummary(error.body) ?? '';

        if (summary.startsWith('path/not_found')) {
          return exp.FileOperationException(
            'File not found during $methodName',
            _getFileOperationType(methodName),
            context: methodName,
            serviceType: serviceType,
            statusCode: 404,
          );
        }

        if (summary.contains('insufficient_space')) {
          return exp.QuotaException(
            'Storage quota exceeded during $methodName',
            exp.QuotaExceptionType.storageQuotaExceeded,
            context: methodName,
            serviceType: serviceType,
          );
        }
      }

      return exp.ServiceException(
        'Dropbox API error during $methodName (${error.statusCode}): ${error.body}',
        exp.ServiceExceptionType.unexpectedError,
        context: methodName,
        serviceType: serviceType,
      );
    }

    if (error is io.SocketException || error is TimeoutException) {
      return exp.NetworkException(
        'Network error during $methodName: $error',
        context: methodName,
        serviceType: serviceType,
      );
    }

    return exp.ServiceException(
      'Unknown error during $methodName: $error',
      exp.ServiceExceptionType.unexpectedError,
      context: methodName,
      serviceType: serviceType,
    );
  }

  exp.FileOperationType _getFileOperationType(String methodName) {
    switch (methodName) {
      case 'uploadFile':
      case 'updateFile':
        return exp.FileOperationType.upload;
      case 'deleteFile':
        return exp.FileOperationType.delete;
      case 'getFileContent':
      case 'downloadFileBytes':
        return exp.FileOperationType.download;
      default:
        return exp.FileOperationType.list;
    }
  }
}
