// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:icloud_storage_sync/models/exceptions.dart';
import 'package:icloud_storage_sync/models/icloud_file_download.dart';
import 'package:storypad/core/remote_storage_clients/storage_client_exception.dart';
import 'package:storypad/core/remote_storage_clients/base_storage_client.dart';
import 'package:icloud_storage_sync/icloud_storage_sync.dart';

class IcloudStorageClient extends BaseStorageClient {
  static const String CLIENT_ID = 'icloud';

  static const String CONTAINER_ID = 'iCloud.com.tc.writestory';

  final IcloudStorageSync _icloud = IcloudStorageSync();

  @override
  String get id => CLIENT_ID;

  @override
  Future<void> authenticate() async {}

  @override
  bool get supportSignOut => false;

  @override
  bool isAuthenticated() => true;

  @override
  Future<void> delete({
    Folder? remoteFileFolder,
    required String remoteFileName,
  }) {
    try {
      String remotePath = remoteFileFolder != null ? '${remoteFileFolder.name}/$remoteFileName' : remoteFileName;
      return _icloud.delete(containerId: CONTAINER_ID, relativePath: remotePath);
    } on InvalidArgumentException catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    } on PlatformException catch (e, s) {
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
    try {
      String remotePath = remoteFileFolder != null ? '${remoteFileFolder.name}/$remoteFileName' : remoteFileName;
      await _icloud.download(
        containerId: CONTAINER_ID,
        relativePath: remotePath,
        destinationFilePath: destinationFilePath,
      );
    } on InvalidArgumentException catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    } catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    }
  }

  @override
  Future<List<RemoteFile>> list([Folder? folder]) async {
    try {
      List<CloudFiles> result = await _icloud.getCloudFiles(containerId: CONTAINER_ID);
      if (folder != null) result = result.where((e) => e.filePath.startsWith(folder.name)).toList();

      return result.map((e) {
        return RemoteFile(
          title: e.title,
          path: e.filePath,
          bytesSize: e.sizeInBytes,
          lastSyncDate: e.lastSyncDt,
        );
      }).toList();
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
    try {
      String remotePath = remoteFileFolder != null ? '${remoteFileFolder.name}/$remoteFileName' : remoteFileName;
      await _icloud.upload(
        containerId: CONTAINER_ID,
        filePath: sourceFilePath,
        destinationRelativePath: remotePath,
      );
    } on InvalidArgumentException catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    } catch (e, s) {
      throw StorageClientException.unknownError(e, s);
    }
  }
}
