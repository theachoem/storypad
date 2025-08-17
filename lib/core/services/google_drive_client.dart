import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
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

  GoogleSignIn get googleSignIn => GoogleSignIn.instance;
  GoogleSignInAccount? _currentAccount;
  
  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];
  
  bool _initialized = false;
  
  StreamSubscription<GoogleSignInAccount?>? _authSubscription;

  
  Future<void> initialize() async {
    if (_initialized) return;
    
    // For mobile platforms, initialize without explicit client IDs as they come from configuration files
    await googleSignIn.initialize();
    
    // Listen to authentication events
    _authSubscription = googleSignIn.authenticationEvents.listen(
      (GoogleSignInAccount? account) {
        _currentAccount = account;
        if (account != null) {
          _updateCurrentUserFromAccount(account);
        } else {
          _currentUser = null;
        }
      },
      onError: (error) {
        debugPrint('GoogleDriveClient authentication error: $error');
        _currentUser = null;
        _currentAccount = null;
      }
    );
    
    _initialized = true;
    
    // Attempt lightweight authentication
    final result = googleSignIn.attemptLightweightAuthentication();
    // On some platforms this returns a Future, on others it doesn't
    if (result is Future) {
      await result;
    }
  }
  
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }
  
  Future<void> _updateCurrentUserFromAccount(GoogleSignInAccount account) async {
    try {
      // Get authorization for the required scopes
      final authorization = await account.authorizationClient.authorizationForScopes(_scopes);
      
      if (authorization != null) {
        _currentUser = GoogleUserObject(
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          accessToken: authorization.accessToken,
          refreshedAt: DateTime.now(),
        );

        await GoogleUserStorage().writeObject(_currentUser!);
      }
    } catch (e) {
      debugPrint('Error updating current user: $e');
    }
  }

  Future<drive.DriveApi?> get googleDriveClient async {
    if (!_initialized) {
      await initialize();
    }
    
    if (_currentAccount == null) return null;
    
    try {
      final authorization = await _currentAccount!.authorizationClient.authorizationForScopes(_scopes);
      if (authorization == null) return null;
      
      final authHeaders = <String, String>{
        'Authorization': 'Bearer ${authorization.accessToken}',
        'X-Goog-AuthUser': '0',
      };
      
      final _GoogleAuthClient client = _GoogleAuthClient(authHeaders);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('Error getting drive client: $e');
      return null;
    }
  }

  Future<void> loadUserLocally() async {
    _currentUser = await GoogleUserStorage().readObject();
  }

  Future<bool> reauthenticateIfNeeded() async {
    if (!_initialized) {
      await initialize();
    }
    
    _currentUser = await GoogleUserStorage().readObject();
    
    // Check if we have a current account from the authentication events
    if (_currentAccount != null) {
      await _updateCurrentUserFromAccount(_currentAccount!);
      return _currentUser != null;
    }
    
    // Try lightweight authentication
    try {
      await googleSignIn.attemptLightweightAuthentication();
      // The result will come through the authentication events stream
      return _currentUser != null;
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In exception during reauthentication: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Reauthentication failed: $e');
      return false;
    }
  }

  Future<bool> signIn() async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      if (googleSignIn.supportsAuthenticate()) {
        await googleSignIn.authenticate(scopeHint: _scopes);
        
        // Wait for the authentication event to update our state
        if (_currentAccount != null) {
          await _updateCurrentUserFromAccount(_currentAccount!);
          return _currentUser != null;
        }
        
        return false;
      } else {
        // For platforms that don't support authenticate (like web),
        // the application should use platform-specific sign-in UI
        debugPrint('Platform does not support authenticate() method. Use platform-specific sign-in UI.');
        return false;
      }
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Sign in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await GoogleUserStorage().remove();
      _currentUser = null;
      _currentAccount = null;
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }
  
  Future<void> disconnect() async {
    try {
      await googleSignIn.disconnect();
      await GoogleUserStorage().remove();
      _currentUser = null;
      _currentAccount = null;
    } catch (e) {
      debugPrint('Disconnect failed: $e');
    }
  }

  Future<bool> canAccessRequestedScopes() async {
    if (!_initialized) {
      await initialize();
    }
    
    if (_currentAccount == null) return false;
    
    try {
      final authorization = await _currentAccount!.authorizationClient.authorizationForScopes(_scopes);
      return authorization != null;
    } catch (e) {
      debugPrint('Error checking scopes: $e');
      return false;
    }
  }

  Future<bool> requestScope() async {
    if (!_initialized) {
      await initialize();
    }
    
    if (!isSignedIn || _currentAccount == null) return false;

    try {
      final authorization = await _currentAccount!.authorizationClient.authorizeScopes(_scopes);
      
      if (authorization != null) {
        // Update the current user with new access token
        _currentUser = GoogleUserObject(
          id: _currentAccount!.id,
          email: _currentAccount!.email,
          displayName: _currentAccount!.displayName,
          photoUrl: _currentAccount!.photoUrl,
          accessToken: authorization.accessToken,
          refreshedAt: DateTime.now(),
        );
        await GoogleUserStorage().writeObject(_currentUser!);
        return true;
      } else {
        // Authorization was not granted
        debugPrint('Authorization for scopes was not granted');
        return false;
      }
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In exception during scope request: ${e.code} - ${e.message}');
      
      // If user cancelled or there's an auth error, we might need to disconnect
      if (e.code == GoogleSignInExceptionCode.canceled || 
          e.code == GoogleSignInExceptionCode.authenticationError) {
        await disconnect();
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting scopes: $e');
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
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return null;

    drive.FileList fileList = await client.files.list(
      q: "name contains '.json' or name contains '.zip'",
      spaces: "appDataFolder",
      pageToken: nextToken,
    );

    return CloudFileListObject.fromGoogleDrive(fileList);
  }

  Future<CloudFileObject?> findFileById(String fileId) async {
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return null;

    Object file = await client.files.get(fileId);
    if (file is drive.File) return CloudFileObject.fromGoogleDrive(file);

    return null;
  }

  Future<CloudFileObject?> fetchLatestBackup() async {
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return null;

    drive.FileList fileList = await client.files.list(
      spaces: "appDataFolder",
      q: "name contains '.json' or name contains '.zip'",
      orderBy: "createdTime desc",
      pageSize: 1,
    );

    if (fileList.files?.firstOrNull == null) return null;
    return CloudFileObject.fromGoogleDrive(fileList.files!.first);
  }

  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async {
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
  }

  Future<bool> deleteFile(String cloudFileId) async {
    drive.DriveApi? client = await googleDriveClient;
    if (client == null) return false;

    await client.files.delete(cloudFileId);
    return true;
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
