import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/services.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/objects/icloud_user_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/icloud_user_storage.dart';

/// Private-container iCloud backup target — file storage under the app's own
/// ubiquity container, in a non-Documents `Data/` root so it never surfaces
/// in the Files app (the private-container analogue of Drive's hidden
/// `appDataFolder`; see docs/app/architecture/backup-sync.md).
///
/// Unlike Drive/Nextcloud, there is no in-app sign-in: Apple gives apps no
/// API to enable iCloud Drive access for themselves, only the user via the
/// OS's own Settings toggle can do that. [signIn]/[reauthenticateIfNeeded]
/// just re-run a live availability check rather than performing any
/// OAuth/credential flow — see [openAppSettings] for the guidance UI's
/// escape hatch. That check is two-tiered: a fast, local, offline native
/// pre-check (does this app's ubiquity container resolve at all — see
/// `ICloudBackupService.isAvailable`), then — only if that passes — a
/// CloudKit `fetchUserRecordID` round-trip for the actual account identity
/// used as [ICloudUserObject.destinationKey]/[ICloudUserObject.globalId].
///
/// Like Nextcloud, ubiquity-container files have no separate stable file-ID
/// concept — [CloudFileObject.id] is the file's path relative to the
/// container's `Data/` root everywhere in this service. Trash is emulated
/// the same way Nextcloud does it: [trashFile] moves a file into a `.trash/`
/// folder mirroring its original relative path.
class ICloudCloudService extends BackupCloudService {
  static const _channel = MethodChannel('default_platform_channel');
  static const _trashFolder = '.trash';

  @override
  BackupServiceType get serviceType => BackupServiceType.icloud;

  ICloudUserObject? _currentUser;

  @override
  ICloudUserObject? get currentUser => _currentUser;

  @override
  Future<void> initialize() async {
    _currentUser = await ICloudUserStorage().readObject();
    await _checkAvailability();
  }

  /// Two-tiered live check: [_isAvailable] (fast, local, offline) gates
  /// whether to attempt [_fetchAccountId] (a real CloudKit round-trip) — see
  /// [_AvailabilityStatus] for why its outcomes are handled differently.
  Future<({_AvailabilityStatus status, bool hasCachedUser})> _checkAvailability() async {
    final available = await _isAvailable();
    if (!available) {
      _currentUser = null;
      return (status: _AvailabilityStatus.notAvailable, hasCachedUser: false);
    }

    final fetched = await _fetchAccountId();
    final accountId = fetched.accountId;
    if (accountId == null) {
      if (fetched.transientFailure) {
        final stored = _currentUser ?? await ICloudUserStorage().readObject();
        final currentFingerprint = await _fetchIdentityTokenFingerprint();
        final identityConfirmedUnchanged =
            stored != null &&
            stored.identityTokenFingerprint != null &&
            currentFingerprint != null &&
            stored.identityTokenFingerprint == currentFingerprint;

        if (identityConfirmedUnchanged) {
          _currentUser = stored;
          return (status: _AvailabilityStatus.transientFailure, hasCachedUser: true);
        }

        // No match (or nothing cached) — don't trust it. Only the in-memory
        // reference is cleared; the persisted record survives, so
        // autoBackupEnabled/account recover normally next successful check.
        _currentUser = null;
        return (status: _AvailabilityStatus.transientFailure, hasCachedUser: false);
      }
      _currentUser = null;
      return (status: _AvailabilityStatus.notAvailable, hasCachedUser: false);
    }

    final currentFingerprint = await _fetchIdentityTokenFingerprint();

    // _currentUser is nulled on every unavailable check, so the persisted
    // record (cleared only by signOut) is what tells "same account, was
    // briefly off" apart from "genuinely different" — preserving
    // autoBackupEnabled across a toggle-off-then-back-on.
    final stored = _currentUser ?? await ICloudUserStorage().readObject();
    if (stored == null || stored.accountId != accountId) {
      final fresh = ICloudUserObject(
        accountId: accountId,
        autoBackupEnabled: true,
        identityTokenFingerprint: currentFingerprint,
      );
      _currentUser = fresh;
      await ICloudUserStorage().writeObject(fresh);
    } else if (stored.identityTokenFingerprint != currentFingerprint) {
      // Keep the preference, refresh the fingerprint so a later transient
      // failure has a current value to compare against.
      final refreshed = stored.copyWith(identityTokenFingerprint: currentFingerprint);
      _currentUser = refreshed;
      await ICloudUserStorage().writeObject(refreshed);
    } else {
      _currentUser = stored;
    }

    return (status: _AvailabilityStatus.available, hasCachedUser: true);
  }

  @override
  void setAutoBackupEnabled(bool enabled) {
    final current = _currentUser;
    if (current == null) return;

    _currentUser = current.copyWith(autoBackupEnabled: enabled);
    ICloudUserStorage().writeObject(_currentUser!);
  }

  /// No-argument OAuth doesn't apply here — this just re-runs the live
  /// availability check, which can legitimately come back false (iCloud
  /// Drive still disabled in Settings) without that being an error. The UI
  /// routes a false result to Settings guidance instead of a generic error.
  /// A transient CloudKit network failure with a cached user falls back to
  /// that cache rather than flipping the tile to "disconnected" over a blip;
  /// with no cached user (nothing to fall back to, e.g. a first-time sign-in
  /// attempted offline) this throws instead of returning `false`, since a
  /// bare `false` here is indistinguishable from iCloud actually being
  /// disabled and would send an offline user to Settings guidance that can't
  /// help them — see [reauthenticateIfNeeded], which makes the same choice.
  @override
  Future<bool> signIn() async {
    final result = await _checkAvailability();
    return switch (result.status) {
      _AvailabilityStatus.available => true,
      _AvailabilityStatus.notAvailable => false,
      _AvailabilityStatus.transientFailure when result.hasCachedUser => true,
      _AvailabilityStatus.transientFailure => throw exp.NetworkException(
        'Could not verify iCloud account — check your connection and try again',
        serviceType: serviceType,
      ),
    };
  }

  @override
  Future<void> signOut() async {
    await ICloudUserStorage().remove();
    _currentUser = null;
  }

  @override
  Future<bool> reauthenticateIfNeeded() async {
    final result = await _checkAvailability();
    return switch (result.status) {
      _AvailabilityStatus.available => true,
      _AvailabilityStatus.transientFailure when result.hasCachedUser => true,
      _AvailabilityStatus.transientFailure => throw exp.NetworkException(
        'Could not verify iCloud account — check your connection and try again',
        serviceType: serviceType,
      ),
      _AvailabilityStatus.notAvailable => throw exp.AuthException(
        'iCloud is not available — enable iCloud Drive for this app in Settings',
        exp.AuthExceptionType.signInRequired,
        serviceType: serviceType,
      ),
    };
  }

  @override
  Future<bool> canAccessRequestedScopes() async => isSignedIn;

  @override
  Future<bool> requestScope() async => isSignedIn;

  /// Opens the app's own Settings page — the only place Apple exposes an
  /// iCloud Drive toggle for an entitled app. Not part of [BackupCloudService];
  /// called directly by the UI when [isSignedIn] is false.
  Future<bool> openAppSettings() async {
    try {
      final result = await _channel.invokeMethod('ICloudBackupService.openAppSettings');
      return result == true;
    } catch (e) {
      AppLogger.d('ICloudCloudService#openAppSettings failed: $e');
      return false;
    }
  }

  String _joinPath(String? folder, String name) => (folder == null || folder.isEmpty) ? name : '$folder/$name';

  String _parentOf(String path) {
    final index = path.lastIndexOf('/');
    return index <= 0 ? '' : path.substring(0, index);
  }

  String _trashPathFor(String originalPath) => '$_trashFolder/$originalPath';

  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async {
    return _run('fetchYearlyBackups', () async {
      final files = await _listFiles('backups');
      final Map<int, CloudFileObject> yearlyBackups = {};

      for (final file in files) {
        final year = file.year;
        if (year == null) continue;

        final existing = yearlyBackups[year];
        final existingTs = existing?.lastUpdatedAt;
        final newTs = file.lastUpdatedAt;
        final isNewer = existing == null || (newTs != null && (existingTs == null || newTs.isAfter(existingTs)));
        if (isNewer) yearlyBackups[year] = file;
      }

      return yearlyBackups;
    });
  }

  Future<List<CloudFileObject>> _listFiles(String folderName) async {
    final raw = await _channel.invokeMethod('ICloudBackupService.listFiles', {
      'relativeFolderPath': folderName,
    });

    final list = (raw as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((entry) => CloudFileObject.fromICloud(entry, remotePath: entry['path'] as String))
        .toList();
  }

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async {
    return _run('getFileContent', () async {
      final bytes = await downloadFileBytes(file.id);
      if (bytes == null) return null;

      if (file.getFileInfo()?.hasCompression == true) {
        final decoded = io.gzip.decode(bytes);
        return (utf8.decode(decoded), bytes.length);
      }

      return (utf8.decode(bytes), bytes.length);
    });
  }

  @override
  Future<List<int>?> downloadFileBytes(String fileId) async {
    return _run('downloadFileBytes', () async {
      final result = await _channel.invokeMethod('ICloudBackupService.downloadFile', {
        'relativePath': fileId,
      });

      if (result == null) return null;
      if (result is Uint8List) return result;
      if (result is List) return result.cast<int>();
      return null;
    });
  }

  @override
  Future<CloudFileObject?> findFileById(String fileId) async {
    return _run('findFileById', () async {
      final raw = await _channel.invokeMethod('ICloudBackupService.statFile', {
        'relativePath': fileId,
      });

      if (raw == null) return null;
      return CloudFileObject.fromICloud(raw as Map, remotePath: fileId);
    });
  }

  @override
  Future<CloudFileObject?> findFileByIdIncludingTrashed(String fileId) async {
    final direct = await findFileById(fileId);
    if (direct != null) return direct;

    return _run('findFileByIdIncludingTrashed', () async {
      final trashPath = _trashPathFor(fileId);
      final raw = await _channel.invokeMethod('ICloudBackupService.statFile', {
        'relativePath': trashPath,
      });

      if (raw == null) return null;
      return CloudFileObject.fromICloud(raw as Map, remotePath: trashPath, trashed: true);
    });
  }

  @override
  Future<bool> deleteFile(String cloudFileId) async {
    return _run('deleteFile', () async {
      final result = await _channel.invokeMethod('ICloudBackupService.deleteFile', {
        'relativePath': cloudFileId,
      });
      return result == true;
    });
  }

  @override
  Future<bool> trashFile(String cloudFileId) async {
    return _run('trashFile', () async {
      final result = await _channel.invokeMethod('ICloudBackupService.moveFile', {
        'fromRelativePath': cloudFileId,
        'toRelativePath': _trashPathFor(cloudFileId),
      });
      return result == true;
    });
  }

  @override
  Future<bool> restoreFileFromTrash(String cloudFileId) async {
    return _run('restoreFileFromTrash', () async {
      final result = await _channel.invokeMethod('ICloudBackupService.moveFile', {
        'fromRelativePath': _trashPathFor(cloudFileId),
        'toRelativePath': cloudFileId,
      });
      return result == true;
    });
  }

  @override
  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async {
    return _run('uploadFile', () async {
      if (!file.existsSync()) {
        throw exp.FileOperationException(
          'Local file does not exist: ${file.path}',
          exp.FileOperationType.upload,
          context: fileName,
          serviceType: serviceType,
        );
      }

      final remotePath = _joinPath(folderName, fileName);
      final raw = await _channel.invokeMethod('ICloudBackupService.uploadFile', {
        'localPath': file.path,
        'relativePath': remotePath,
      });

      if (raw == null) return null;
      return CloudFileObject.fromICloud(raw as Map, remotePath: remotePath);
    });
  }

  @override
  Future<CloudFileObject?> updateFile({
    required String fileId,
    required String fileName,
    required io.File file,
  }) async {
    return _run('updateFile', () async {
      if (!file.existsSync()) {
        throw exp.FileOperationException(
          'Local file does not exist: ${file.path}',
          exp.FileOperationType.upload,
          context: fileName,
          serviceType: serviceType,
        );
      }

      final remotePath = _joinPath(_parentOf(fileId), fileName);
      final raw = await _channel.invokeMethod('ICloudBackupService.uploadFile', {
        'localPath': file.path,
        'relativePath': remotePath,
      });

      // Yearly backup filenames embed a timestamp, so an "update" writes a
      // new path; clean up the old one once the new content has landed.
      if (remotePath != fileId) {
        try {
          await _channel.invokeMethod('ICloudBackupService.deleteFile', {'relativePath': fileId});
        } catch (e) {
          AppLogger.d('ICloudCloudService#updateFile: failed to remove old file $fileId: $e');
        }
      }

      if (raw == null) return null;
      return CloudFileObject.fromICloud(raw as Map, remotePath: remotePath);
    });
  }

  @override
  Future<List<CloudFileObject>> listFilesInFolder(String folderName) async {
    return _run('listFilesInFolder', () => _listFiles(folderName));
  }

  /// No per-app ubiquity storage quota API exists — unlike Drive/Nextcloud,
  /// there's nothing to report here.
  @override
  Future<CloudStorageQuotaObject?> fetchStorageQuota() async => null;

  Future<bool> _isAvailable() async {
    try {
      final result = await _channel.invokeMethod('ICloudBackupService.isAvailable');
      return result == true;
    } catch (e) {
      AppLogger.d('ICloudCloudService#_isAvailable failed: $e');
      return false;
    }
  }

  /// [transientFailure] distinguishes "CloudKit was briefly unreachable"
  /// (native `NETWORK` code) from every other failure, which callers must
  /// treat as "not signed in" — see [_checkAvailability].
  Future<({String? accountId, bool transientFailure})> _fetchAccountId() async {
    try {
      final result = await _channel.invokeMethod('ICloudBackupService.fetchAccountId');
      return (accountId: result as String?, transientFailure: false);
    } on PlatformException catch (e) {
      AppLogger.d('ICloudCloudService#_fetchAccountId failed (${e.code}): ${e.message}');
      return (accountId: null, transientFailure: e.code == 'NETWORK');
    } catch (e) {
      AppLogger.d('ICloudCloudService#_fetchAccountId failed: $e');
      return (accountId: null, transientFailure: false);
    }
  }

  /// Local, no-network "is this still the same iCloud account" check, used
  /// only by [_checkAvailability] when a live `fetchAccountId` fails
  /// transiently and can't confirm the account itself. Why it's needed:
  ///
  /// - t0: signed in as account A, `fetchAccountId` succeeds, fingerprint
  ///   for A saved.
  /// - t1: device's iCloud account is switched to B.
  /// - t2: app re-checks; `fetchAccountId` happens to fail (network blip),
  ///   right as B's container has already taken over.
  ///   - Before this check: A's cached account gets reused for B's files.
  ///   - After: the fingerprint at t2 no longer matches A's, so the cache
  ///     is dropped instead of silently reused for the wrong account.
  ///
  /// A failed fetch returns `null` rather than throwing — a missing
  /// fingerprint just means "no match", already the safe default.
  Future<String?> _fetchIdentityTokenFingerprint() async {
    try {
      final result = await _channel.invokeMethod('ICloudBackupService.fetchIdentityTokenFingerprint');
      return result as String?;
    } catch (e) {
      AppLogger.d('ICloudCloudService#_fetchIdentityTokenFingerprint failed: $e');
      return null;
    }
  }

  Future<T> _run<T>(String methodName, Future<T> Function() operation) async {
    if (!isSignedIn) {
      throw exp.AuthException(
        'iCloud is not available',
        exp.AuthExceptionType.signInRequired,
        context: methodName,
        serviceType: serviceType,
      );
    }

    try {
      return await operation();
    } catch (e) {
      throw _buildException(e, methodName);
    }
  }

  exp.BackupException _buildException(dynamic error, String methodName) {
    if (error is exp.BackupException) return error;

    if (error is PlatformException) {
      switch (error.code) {
        case 'NO_CONTAINER':
          return exp.AuthException(
            error.message ?? 'iCloud container unavailable',
            exp.AuthExceptionType.signInRequired,
            context: methodName,
            serviceType: serviceType,
          );
        case 'NETWORK':
          return exp.NetworkException(
            error.message ?? 'Network error during $methodName',
            context: methodName,
            serviceType: serviceType,
          );
        case 'NOT_FOUND':
          return exp.FileOperationException(
            error.message ?? 'File not found during $methodName',
            _getFileOperationType(methodName),
            context: methodName,
            serviceType: serviceType,
          );
        default:
          return exp.ServiceException(
            error.message ?? 'Unknown error during $methodName',
            exp.ServiceExceptionType.unexpectedError,
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
      case 'downloadFileBytes':
        return exp.FileOperationType.download;
      default:
        return exp.FileOperationType.list;
    }
  }
}

/// [transientFailure] exists separately from [notAvailable] because
/// `fetchAccountId` can fail for reasons that have nothing to do with iCloud
/// actually being off — e.g. the app resumes with no signal yet (subway,
/// weak wifi). Collapsing that into [notAvailable] would wrongly disconnect
/// a correctly-configured user and send them to Settings guidance over a
/// momentary blip, so it falls back to the cached account instead — guarded
/// by [ICloudCloudService._fetchIdentityTokenFingerprint] so a genuine
/// account switch at the same moment still isn't silently trusted.
enum _AvailabilityStatus { available, notAvailable, transientFailure }
