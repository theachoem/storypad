import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/web_dev_user_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:storypad/core/storages/web_dev_user_object_storage.dart';

// ignore: depend_on_referenced_packages
import 'package:xml/xml.dart';

class WebDavCloudService extends BackupCloudService {
  static const String appFolder = 'StoryPad';

  final Future<WebDevUserObject?> Function() onSignIn;

  @override
  WebDevUserObject? get currentUser => _currentUser;
  WebDevUserObject? _currentUser;

  WebDavCloudService({
    required this.onSignIn,
  });

  @override
  Future<bool> canAccessRequestedScopes() {
    if (_currentUser == null) return Future.value(false);
    return Future.value(true);
  }

  @override
  Future<bool> deleteFile(String fileId) async {
    try {
      if (_currentUser == null) {
        throw exp.AuthException(
          'Not authenticated',
          exp.AuthExceptionType.signInRequired,
          serviceType: serviceType,
        );
      }

      final url = Uri.parse('${_currentUser!.serverUrl}/webdav/$appFolder/$fileId');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _handleApiException(e, 'deleteFile', context: fileId);
      rethrow;
    }
  }

  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async {
    try {
      if (_currentUser == null) {
        throw exp.AuthException(
          'Not authenticated',
          exp.AuthExceptionType.signInRequired,
          serviceType: serviceType,
        );
      }

      await _ensureFolderExists('$appFolder/backups');

      final url = Uri.parse('${_currentUser!.serverUrl}/webdav/$appFolder/backups/');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));

      final request = http.Request('PROPFIND', url)
        ..headers.addAll({
          'Authorization': 'Basic $credentials',
          'Depth': '1',
          'Content-Type': 'text/xml',
        })
        ..body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:getcontentlength/>
    <d:getlastmodified/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        return {};
      }

      final document = XmlDocument.parse(responseBody);
      var responses = document.findAllElements('response', namespace: '*');

      Map<int, CloudFileObject> yearlyBackups = {};

      for (var responseEl in responses) {
        var hrefElements = responseEl.findAllElements('href', namespace: '*');
        if (hrefElements.isEmpty) continue;

        final href = hrefElements.first.innerText;
        if (href.endsWith('/backups/') || href.endsWith('/$appFolder/')) continue;

        final fileName = Uri.decodeComponent(href.split('/').last);
        if (fileName.isEmpty) continue;

        final fileId = 'backups/$fileName';
        final cloudFile = CloudFileObject(
          fileName: fileName,
          id: fileId,
          description: null,
        );

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

  @override
  Future<CloudFileObject?> findFileById(String fileId) async {
    if (_currentUser == null) return null;

    try {
      final url = Uri.parse('${_currentUser!.serverUrl}/webdav/$appFolder/$fileId');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));

      final response = http.Request('PROPFIND', url)
        ..headers.addAll({
          'Authorization': 'Basic $credentials',
          'Depth': '0',
          'Content-Type': 'text/xml',
        })
        ..body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:getcontentlength/>
    <d:getlastmodified/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await response.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        return null;
      }

      final document = XmlDocument.parse(responseBody);
      var responseElements = document.findAllElements('response', namespace: '*');
      final responseEl = responseElements.firstOrNull;

      if (responseEl == null) return null;

      // Get href to extract filename
      var hrefElements = responseEl.findAllElements('href', namespace: '*');
      if (hrefElements.isEmpty) return null;

      final href = hrefElements.first.innerText;
      final fileName = Uri.decodeComponent(href.split('/').last);

      return CloudFileObject(
        fileName: fileName,
        id: fileId,
        description: null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async {
    try {
      if (_currentUser == null) return null;

      final url = Uri.parse('${_currentUser!.serverUrl}/webdav/$appFolder/${file.id}');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));

      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bytes = response.bodyBytes;

      return (utf8.decode(bytes), bytes.length);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> initialize() async {
    _currentUser = await WebDevUserObjectStorage().readObject();
  }

  /// Test WebDAV connection by trying to list root directory
  Future<bool> testConnection() async {
    if (_currentUser == null) return false;

    try {
      final baseUrl = _currentUser!.serverUrl.endsWith('/')
          ? _currentUser!.serverUrl.substring(0, _currentUser!.serverUrl.length - 1)
          : _currentUser!.serverUrl;
      final url = Uri.parse('$baseUrl/webdav/');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));

      final request = http.Request('PROPFIND', url)
        ..headers.addAll({
          'Authorization': 'Basic $credentials',
          'Depth': '0',
        });

      final response = await request.send();
      await response.stream.drain();

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      AppLogger.error('WebDAV connection test failed: $e');
      return false;
    }
  }

  /// Handle and map WebDAV exceptions to appropriate BackupExceptions
  void _handleApiException(dynamic error, String operation, {String? context}) {
    if (error is exp.BackupException) return;

    if (error is io.SocketException || error is TimeoutException) {
      throw exp.NetworkException(
        'Network error during $operation: $error',
        context: context,
        serviceType: serviceType,
      );
    }

    throw exp.ServiceException(
      'WebDAV error during $operation: $error',
      exp.ServiceExceptionType.unexpectedError,
      context: context,
      serviceType: serviceType,
    );
  }

  @override
  Future<bool> reauthenticateIfNeeded() {
    if (_currentUser == null) return Future.value(false);
    return Future.value(true);
  }

  @override
  Future<bool> requestScope() {
    return Future.value(true);
  }

  @override
  BackupServiceType get serviceType => BackupServiceType.web_dav;

  @override
  Future<bool> signIn() async {
    var result = await onSignIn();

    if (result != null) {
      _currentUser = result;
      await WebDevUserObjectStorage().writeObject(_currentUser!);
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<void> signOut() {
    _currentUser = null;
    return WebDevUserObjectStorage().remove();
  }

  @override
  Future<CloudFileObject?> updateFile({required String fileId, required String fileName, required io.File file}) async {
    try {
      if (_currentUser == null) {
        throw exp.AuthException(
          'Not authenticated',
          exp.AuthExceptionType.signInRequired,
          serviceType: serviceType,
        );
      }

      if (!file.existsSync()) {
        throw exp.FileOperationException(
          'File not found: ${file.path}',
          exp.FileOperationType.upload,
          context: fileName,
          serviceType: serviceType,
        );
      }

      final url = Uri.parse('${_currentUser!.serverUrl}/webdav/$appFolder/$fileId');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));
      final fileBytes = await file.readAsBytes();

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: fileBytes,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return CloudFileObject(
          fileName: fileName,
          id: fileId,
          description: null,
        );
      }

      throw exp.FileOperationException(
        'Update failed with status ${response.statusCode}',
        exp.FileOperationType.upload,
        context: fileName,
        serviceType: serviceType,
      );
    } catch (e) {
      _handleApiException(e, 'updateFile', context: fileName);
      rethrow;
    }
  }

  @override
  Future<CloudFileObject?> uploadFile(String fileName, io.File file, {String? folderName}) async {
    try {
      if (_currentUser == null) {
        throw exp.AuthException(
          'Not authenticated',
          exp.AuthExceptionType.signInRequired,
          serviceType: serviceType,
        );
      }

      if (!file.existsSync()) {
        throw exp.FileOperationException(
          'File not found: ${file.path}',
          exp.FileOperationType.upload,
          context: fileName,
          serviceType: serviceType,
        );
      }

      await _ensureFolderExists(appFolder);
      if (folderName != null) {
        await _ensureFolderExists('$appFolder/$folderName');
      }

      final filePath = folderName != null ? '$folderName/$fileName' : fileName;
      final pathSegments = [appFolder, ...filePath.split('/')].map((s) => Uri.encodeComponent(s)).join('/');
      final baseUrl = _currentUser!.serverUrl.endsWith('/')
          ? _currentUser!.serverUrl.substring(0, _currentUser!.serverUrl.length - 1)
          : _currentUser!.serverUrl;
      final url = Uri.parse('$baseUrl/webdav/$pathSegments');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));
      final fileBytes = await file.readAsBytes();

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: fileBytes,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return CloudFileObject(
          fileName: fileName,
          id: filePath,
          description: null,
        );
      }

      throw exp.FileOperationException(
        'Upload failed with status ${response.statusCode}',
        exp.FileOperationType.upload,
        context: fileName,
        serviceType: serviceType,
      );
    } catch (e) {
      _handleApiException(e, 'uploadFile', context: fileName);
      rethrow;
    }
  }

  /// Check if folder exists and create if it doesn't
  /// Non-fatal - best-effort operation
  Future<void> _ensureFolderExists(String folderPath) async {
    if (_currentUser == null) return;

    try {
      final encodedPath = folderPath.split('/').map((s) => Uri.encodeComponent(s)).join('/');
      final baseUrl = _currentUser!.serverUrl.endsWith('/')
          ? _currentUser!.serverUrl.substring(0, _currentUser!.serverUrl.length - 1)
          : _currentUser!.serverUrl;
      final folderUrl = Uri.parse('$baseUrl/webdav/$encodedPath/');
      final credentials = base64Encode(utf8.encode('${_currentUser!.username}:${_currentUser!.password}'));

      final checkRequest = http.Request('PROPFIND', folderUrl)
        ..headers.addAll({
          'Authorization': 'Basic $credentials',
          'Depth': '0',
        });

      final checkResponse = await checkRequest.send();
      await checkResponse.stream.drain();

      if (checkResponse.statusCode >= 200 && checkResponse.statusCode < 300) {
        return;
      }

      // Create parent folders recursively
      final parts = folderPath.split('/');
      String currentPath = '';

      for (final part in parts) {
        if (part.isEmpty) continue;
        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

        final encodedCurrentPath = currentPath.split('/').map((s) => Uri.encodeComponent(s)).join('/');
        final currentUrl = Uri.parse('$baseUrl/webdav/$encodedCurrentPath/');

        final createRequest = http.Request('MKCOL', currentUrl)
          ..headers.addAll({'Authorization': 'Basic $credentials'});

        final createResponse = await createRequest.send();
        await createResponse.stream.drain();
      }
    } catch (e) {
      // Non-fatal - folder creation is best-effort
    }
  }
}
