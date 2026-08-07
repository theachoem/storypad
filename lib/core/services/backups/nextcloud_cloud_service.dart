import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

// ignore: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/objects/nextcloud_user_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/nextcloud_user_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:webdav_client/webdav_client.dart' as webdav;

/// Self-hosted WebDAV backup target (e.g. a Nextcloud instance on Railway).
///
/// Unlike Drive, there's no separate stable file-ID concept over plain WebDAV —
/// the remote path itself is used as [CloudFileObject.id] everywhere in this
/// service. Trash is emulated (no universal WebDAV trash API): [trashFile] moves
/// a file into a `.trash/` folder that mirrors the original relative path, and
/// [restoreFileFromTrash] moves it back using that same mapping.
class NextcloudCloudService extends BackupCloudService {
  @override
  BackupServiceType get serviceType => BackupServiceType.nextcloud;

  /// The account's configured storage location, e.g. `Journals/MyDiary` —
  /// falls back to [NextcloudUserObject.defaultFolderName] for accounts
  /// connected before this was customizable (or that left it blank).
  String get _rootFolder => _currentUser?.folderName ?? NextcloudUserObject.defaultFolderName;
  String get _trashFolder => '$_rootFolder/.trash';

  /// Trims slashes, drops empty/`.`/`..` segments (defensive — this is the
  /// user's own account, but a stray `..` should never be handed to WebDAV
  /// path-building), and collapses back to a clean relative path. Returns
  /// null (meaning "use the default") when nothing usable is left.
  static String? sanitizeFolderName(String? input) {
    if (input == null) return null;

    final segments = input
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty && segment != '.' && segment != '..');

    final cleaned = segments.join('/');
    return cleaned.isEmpty ? null : cleaned;
  }

  NextcloudUserObject? _currentUser;

  @override
  NextcloudUserObject? get currentUser => _currentUser;

  @override
  bool get isSignedIn => _currentUser != null;

  webdav.Client? _client;

  @override
  Future<void> initialize() async {
    _currentUser = await NextcloudUserStorage().readObject();
    if (_currentUser != null) _client = _buildClient(_currentUser!);
  }

  webdav.Client _buildClient(NextcloudUserObject user) {
    return webdav.newClient(
      '${user.serverUrl}/remote.php/dav/files/${user.username}',
      user: user.username,
      password: user.appPassword,
    );
  }

  @override
  void setAutoBackupEnabled(bool enabled) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(autoBackupEnabled: enabled);
    NextcloudUserStorage().writeObject(_currentUser!);
  }

  /// Not part of [BackupCloudService] — Nextcloud's auth is a plain
  /// server/username/app-password form, not a no-argument OAuth flow, so the
  /// connect sheet calls this directly instead of the generic [signIn].
  Future<bool> connect({
    required String serverUrl,
    required String username,
    required String appPassword,
    String? folderName,
  }) async {
    final normalizedServerUrl = serverUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final candidate = NextcloudUserObject(
      serverUrl: normalizedServerUrl,
      username: username.trim(),
      appPassword: appPassword,
      autoBackupEnabled: true,
      folderName: sanitizeFolderName(folderName),
    );

    final client = _buildClient(candidate);

    try {
      await client.ping();
    } catch (e) {
      throw exp.AuthException(
        'Could not connect to Nextcloud: $e',
        exp.AuthExceptionType.signInFailed,
        context: 'connect',
        serviceType: serviceType,
      );
    }

    _client = client;
    _currentUser = candidate;
    await NextcloudUserStorage().writeObject(candidate);
    return true;
  }

  /// Generic no-argument sign-in doesn't apply to this service — the connect
  /// sheet calls [connect] with credentials directly instead of going through
  /// [BackupRepository.signIn].
  @override
  Future<bool> signIn() async => isSignedIn;

  @override
  Future<void> signOut() async {
    await NextcloudUserStorage().remove();
    _currentUser = null;
    _client = null;
  }

  @override
  Future<bool> reauthenticateIfNeeded() async {
    if (_currentUser == null || _client == null) {
      throw exp.AuthException(
        'No stored user found',
        exp.AuthExceptionType.signInRequired,
        serviceType: serviceType,
      );
    }

    try {
      await _client!.ping();
      return true;
    } catch (e) {
      // App passwords don't refresh themselves — if the ping fails the
      // credentials were revoked server-side, so the user must reconnect.
      throw exp.AuthException(
        'Nextcloud credentials are no longer valid: $e',
        exp.AuthExceptionType.tokenRevoked,
        context: 'reauthenticateIfNeeded',
        serviceType: serviceType,
      );
    }
  }

  @override
  Future<bool> canAccessRequestedScopes() async => isSignedIn;

  @override
  Future<bool> requestScope() async => isSignedIn;

  String get _appRootPath => '/$_rootFolder';

  String _folderPath(String? folderName) => folderName != null ? '$_appRootPath/$folderName' : _appRootPath;

  String _trashPathFor(String originalPath) {
    final relative = originalPath.startsWith(_appRootPath)
        ? originalPath.substring(_appRootPath.length).replaceFirst(RegExp(r'^/+'), '')
        : originalPath.replaceFirst(RegExp(r'^/+'), '');
    return '/$_trashFolder/$relative';
  }

  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async {
    return _executeWithRetry(
      methodName: 'fetchYearlyBackups',
      operation: () async {
        final client = _getAuthenticatedClient();
        final backupsPath = _folderPath('backups');

        List<webdav.File> files;
        try {
          files = await client.readDir(backupsPath);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return {};
          rethrow;
        }

        final Map<int, CloudFileObject> yearlyBackups = {};
        for (final file in files) {
          if (file.isDir == true || file.name == null) continue;

          final cloudFile = CloudFileObject.fromNextcloud(file, remotePath: '$backupsPath/${file.name}');
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
    final client = _getAuthenticatedClient();

    return _executeWithRetry(
      methodName: 'getFileContent',
      operation: () async {
        final bytes = await _readBytes(client, file.id);
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
    final client = _getAuthenticatedClient();

    return _executeWithRetry(
      methodName: 'downloadFileBytes',
      operation: () => _readBytes(client, fileId),
    );
  }

  Future<List<int>?> _readBytes(webdav.Client client, String fileId) async {
    try {
      return await client.read(fileId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<CloudFileObject?> findFileById(String fileId) async {
    final client = _getAuthenticatedClient();

    return _executeWithRetry(
      methodName: 'findFileById',
      operation: () async {
        try {
          final file = await client.readProps(fileId);
          return CloudFileObject.fromNextcloud(file, remotePath: fileId);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      },
    );
  }

  @override
  Future<CloudFileObject?> findFileByIdIncludingTrashed(String fileId) async {
    final direct = await findFileById(fileId);
    if (direct != null) return direct;

    final client = _getAuthenticatedClient();
    final trashPath = _trashPathFor(fileId);

    return _executeWithRetry(
      methodName: 'findFileByIdIncludingTrashed',
      operation: () async {
        try {
          final file = await client.readProps(trashPath);
          return CloudFileObject.fromNextcloud(file, remotePath: trashPath, trashed: true);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      },
    );
  }

  @override
  Future<bool> deleteFile(String cloudFileId) async {
    final client = _getAuthenticatedClient();

    return _executeWithRetry(
      methodName: 'deleteFile',
      operation: () async {
        await client.remove(cloudFileId);
        return true;
      },
    );
  }

  @override
  Future<bool> trashFile(String cloudFileId) async {
    final client = _getAuthenticatedClient();
    final trashPath = _trashPathFor(cloudFileId);

    return _executeWithRetry(
      methodName: 'trashFile',
      operation: () async {
        await client.mkdirAll(_parentOf(trashPath));
        await client.rename(cloudFileId, trashPath, true);
        return true;
      },
    );
  }

  @override
  Future<bool> restoreFileFromTrash(String cloudFileId) async {
    final client = _getAuthenticatedClient();
    final trashPath = _trashPathFor(cloudFileId);

    return _executeWithRetry(
      methodName: 'restoreFileFromTrash',
      operation: () async {
        await client.mkdirAll(_parentOf(cloudFileId));
        await client.rename(trashPath, cloudFileId, true);
        return true;
      },
    );
  }

  String _parentOf(String path) {
    final trimmed = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final index = trimmed.lastIndexOf('/');
    return index <= 0 ? '/' : trimmed.substring(0, index);
  }

  @override
  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async {
    final client = _getAuthenticatedClient();
    final folderPath = _folderPath(folderName);
    final remotePath = '$folderPath/$fileName';

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

        await client.mkdirAll(folderPath);
        await client.writeFromFile(file.path, remotePath);

        final uploaded = await client.readProps(remotePath);
        return CloudFileObject.fromNextcloud(uploaded, remotePath: remotePath);
      },
    );
  }

  @override
  Future<CloudFileObject?> updateFile({
    required String fileId,
    required String fileName,
    required io.File file,
  }) async {
    final client = _getAuthenticatedClient();
    final folderPath = _parentOf(fileId);
    final remotePath = '$folderPath/$fileName';

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

        await client.mkdirAll(folderPath);
        await client.writeFromFile(file.path, remotePath);

        // Yearly backup filenames embed a timestamp, so an "update" writes a
        // new path; clean up the old one once the new content has landed.
        if (remotePath != fileId) {
          try {
            await client.remove(fileId);
          } catch (e) {
            AppLogger.d('NextcloudCloudService#updateFile: failed to remove old file $fileId: $e');
          }
        }

        final uploaded = await client.readProps(remotePath);
        return CloudFileObject.fromNextcloud(uploaded, remotePath: remotePath);
      },
    );
  }

  @override
  Future<List<CloudFileObject>> listFilesInFolder(String folderName) async {
    final client = _getAuthenticatedClient();
    final folderPath = _folderPath(folderName);

    return _executeWithRetry(
      methodName: 'listFilesInFolder',
      operation: () async {
        List<webdav.File> files;
        try {
          files = await client.readDir(folderPath);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return <CloudFileObject>[];
          rethrow;
        }

        return files
            .where((file) => file.isDir != true && file.name != null)
            .map((file) => CloudFileObject.fromNextcloud(file, remotePath: '$folderPath/${file.name}'))
            .toList();
      },
    );
  }

  @override
  Future<CloudStorageQuotaObject?> fetchStorageQuota() async {
    if (_currentUser == null) return null;

    try {
      final appUsage = await _calculateAppUsageBytes();
      final accountQuota = await _fetchAccountQuota();

      return CloudStorageQuotaObject(
        appUsageInBytes: appUsage,
        accountUsageInBytes: accountQuota?.$1,
        limitInBytes: accountQuota?.$2,
      );
    } catch (e, s) {
      AppLogger.error('NextcloudCloudService#fetchStorageQuota failed: $e', stackTrace: s);
      return null;
    }
  }

  Future<int> _calculateAppUsageBytes() async {
    final client = _getAuthenticatedClient();
    return _sumFolderBytes(client, _appRootPath);
  }

  Future<int> _sumFolderBytes(webdav.Client client, String path) async {
    List<webdav.File> files;
    try {
      files = await client.readDir(path);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return 0;
      rethrow;
    }

    int total = 0;
    for (final file in files) {
      if (file.isDir == true) {
        total += await _sumFolderBytes(client, '$path/${file.name}');
      } else {
        total += file.size ?? 0;
      }
    }
    return total;
  }

  /// Account-wide usage/limit via the OCS Provisioning API — not exposed by
  /// the WebDAV client, so this is a small standalone request.
  /// Returns (usedBytes, limitBytes), or null if unsupported/unreachable.
  Future<(int, int?)?> _fetchAccountQuota() async {
    final user = _currentUser;
    if (user == null) return null;

    try {
      final uri = Uri.parse('${user.serverUrl}/ocs/v1.php/cloud/users/${user.username}');
      final response = await http.get(
        uri,
        headers: {
          ...user.authHeaders,
          'OCS-APIRequest': 'true',
        },
      );

      if (response.statusCode != 200) return null;

      final body = response.body;
      final used = _extractXmlTagValue(body, 'used');
      final total = _extractXmlTagValue(body, 'total');
      if (used == null) return null;

      return (int.tryParse(used) ?? 0, total != null ? int.tryParse(total) : null);
    } catch (e) {
      AppLogger.d('NextcloudCloudService#_fetchAccountQuota failed: $e');
      return null;
    }
  }

  String? _extractXmlTagValue(String xml, String tag) {
    final match = RegExp('<$tag>([^<]*)</$tag>').firstMatch(xml);
    return match?.group(1);
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

  webdav.Client _getAuthenticatedClient() {
    final client = _client;
    if (client == null || !isSignedIn) {
      throw exp.AuthException(
        'Failed to get authenticated Nextcloud client',
        exp.AuthExceptionType.signInRequired,
        serviceType: serviceType,
      );
    }
    return client;
  }

  exp.BackupException _buildException(dynamic error, String methodName) {
    if (error is exp.BackupException) return error;

    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        return exp.AuthException(
          'Authentication failed during $methodName',
          exp.AuthExceptionType.tokenRevoked,
          context: methodName,
          serviceType: serviceType,
        );
      }

      if (statusCode == 404) {
        return exp.FileOperationException(
          'File not found during $methodName',
          _getFileOperationType(methodName),
          context: methodName,
          serviceType: serviceType,
          statusCode: 404,
        );
      }

      if (statusCode == 507) {
        return exp.QuotaException(
          'Storage quota exceeded during $methodName',
          exp.QuotaExceptionType.storageQuotaExceeded,
          context: methodName,
          serviceType: serviceType,
        );
      }

      if (statusCode == 429) {
        return exp.QuotaException(
          'Rate limit exceeded during $methodName',
          exp.QuotaExceptionType.rateLimitExceeded,
          context: methodName,
          serviceType: serviceType,
        );
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return exp.NetworkException(
          'Network error during $methodName: $error',
          context: methodName,
          serviceType: serviceType,
        );
      }
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
        return exp.FileOperationType.download;
      default:
        return exp.FileOperationType.list;
    }
  }
}
