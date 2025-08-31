import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:icloud_storage_sync/models/icloud_file.dart';

import 'icloud_storage_sync_platform_interface.dart';

/// An implementation of [IcloudStorageSyncPlatform] that uses method channels.
class MethodChannelIcloudStorageSync extends IcloudStorageSyncPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('icloud_storage_sync');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  /// Gathers iCloud files and their metadata.
  ///
  /// [containerId] is the iCloud container identifier.
  /// [onUpdate] is an optional callback for receiving updates.
  @override
  Future<List<ICloudFile>> gather({
    required String containerId,
    StreamHandler<List<ICloudFile>>? onUpdate,
  }) async {
    // Generate a unique event channel name if updates are requested
    final eventChannelName = onUpdate == null
        ? ''
        : _generateEventChannelName('gather', containerId);

    if (onUpdate != null) {
      // Create an event channel for updates
      await methodChannel.invokeMethod(
          'createEventChannel', {'eventChannelName': eventChannelName});

      // Set up the event channel to receive updates
      final gatherEventChannel = EventChannel(eventChannelName);
      final stream = gatherEventChannel
          .receiveBroadcastStream()
          .where((event) => event is List)
          .map<List<ICloudFile>>((event) => _mapFilesFromDynamicList(
              List<Map<dynamic, dynamic>>.from(event)));

      onUpdate(stream);
    }

    // Invoke the gather method on the native side
    final mapList =
        await methodChannel.invokeListMethod<Map<dynamic, dynamic>>('gather', {
      'containerId': containerId,
      'eventChannelName': eventChannelName,
    });

    return _mapFilesFromDynamicList(mapList);
  }

  /// Retrieves iCloud files for a specific container.
  @override
  Future<void> getCloudFiles({
    required String containerId,
  }) async {
    return await methodChannel.invokeMethod('getICloudFiles', {
      'containerId': containerId,
    });
  }

  /// Uploads a file to iCloud.
  ///
  /// [containerId] is the iCloud container identifier.
  /// [filePath] is the local file path to upload.
  /// [destinationRelativePath] is the relative path in iCloud to store the file.
  /// [onProgress] is an optional callback for upload progress updates.
  @override
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
    StreamHandler<double>? onProgress,
  }) async {
    var eventChannelName = '';

    if (onProgress != null) {
      // Create an event channel for progress updates
      eventChannelName = _generateEventChannelName('upload', containerId);
      await methodChannel.invokeMethod(
          'createEventChannel', {'eventChannelName': eventChannelName});

      final uploadEventChannel = EventChannel(eventChannelName);
      final stream = uploadEventChannel
          .receiveBroadcastStream()
          .where((event) => event is double)
          .map((event) => event as double);

      onProgress(stream);
    }

    // Invoke the upload method on the native side
    await methodChannel.invokeMethod('upload', {
      'containerId': containerId,
      'localFilePath': filePath,
      'cloudFileName': destinationRelativePath,
      'eventChannelName': eventChannelName
    });
  }

  /// Downloads a file from iCloud.
  ///
  /// [containerId] is the iCloud container identifier.
  /// [relativePath] is the relative path of the file in iCloud.
  /// [destinationFilePath] is the local path to save the downloaded file.
  /// [onProgress] is an optional callback for download progress updates.
  @override
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
    StreamHandler<double>? onProgress,
  }) async {
    var eventChannelName = '';

    if (onProgress != null) {
      // Create an event channel for progress updates
      eventChannelName = _generateEventChannelName('download', containerId);
      await methodChannel.invokeMethod(
          'createEventChannel', {'eventChannelName': eventChannelName});

      final downloadEventChannel = EventChannel(eventChannelName);
      final stream = downloadEventChannel
          .receiveBroadcastStream()
          .where((event) => event is double)
          .map((event) => event as double);

      onProgress(stream);
    }

    // Invoke the download method on the native side
    await methodChannel.invokeMethod('download', {
      'containerId': containerId,
      'cloudFileName': relativePath,
      'localFilePath': destinationFilePath,
      'eventChannelName': eventChannelName
    });
  }

  /// Deletes a file from iCloud.
  ///
  /// [containerId] is the iCloud container identifier.
  /// [relativePath] is the relative path of the file to delete in iCloud.
  @override
  Future<void> delete({
    required containerId,
    required String relativePath,
  }) async {
    await methodChannel.invokeMethod('delete', {
      'containerId': containerId,
      'cloudFileName': relativePath,
    });
  }

  /// Moves a file within iCloud.
  ///
  /// [containerId] is the iCloud container identifier.
  /// [fromRelativePath] is the current relative path of the file in iCloud.
  /// [toRelativePath] is the new relative path for the file in iCloud.
  @override
  Future<void> move({
    required containerId,
    required String fromRelativePath,
    required String toRelativePath,
  }) async {
    await methodChannel.invokeMethod('move', {
      'containerId': containerId,
      'atRelativePath': fromRelativePath,
      'toRelativePath': toRelativePath,
    });
  }

  /// Converts a list of dynamic maps to a list of ICloudFile objects.
  List<ICloudFile> _mapFilesFromDynamicList(
      List<Map<dynamic, dynamic>>? mapList) {
    List<ICloudFile> files = [];
    if (mapList != null) {
      for (final map in mapList) {
        try {
          files.add(ICloudFile.fromMap(map));
        } catch (ex) {
          if (kDebugMode) {
            print(
                'WARNING: icloud_storage plugin gatherFiles method has to omit a file as it could not map $map to iCloudFile; Exception: $ex');
          }
        }
      }
    }
    return files;
  }

  /// Generates a unique event channel name.
  ///
  /// This is used to create distinct event channels for different operations.
  String _generateEventChannelName(String eventType, String containerId,
          [String? additionalIdentifier]) =>
      [
        'icloud_storage',
        'event',
        eventType,
        containerId,
        ...(additionalIdentifier == null ? [] : [additionalIdentifier]),
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}'
      ].join('/');
}
