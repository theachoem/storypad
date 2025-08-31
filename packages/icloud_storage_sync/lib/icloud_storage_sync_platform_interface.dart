import 'package:icloud_storage_sync/models/icloud_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'icloud_storage_sync_method_channel.dart';

/// A function type alias for handling streams of data.
typedef StreamHandler<T> = void Function(Stream<T>);

/// The interface that platform-specific implementations of icloud_sync must implement.
///
/// This abstract class defines the contract for platform-specific implementations.
/// It ensures that all platforms provide the same set of methods for iCloud operations.
abstract class IcloudStorageSyncPlatform extends PlatformInterface {
  /// Constructs a IcloudStorageSyncPlatform.
  IcloudStorageSyncPlatform() : super(token: _token);

  static final Object _token = Object();

  static IcloudStorageSyncPlatform _instance = MethodChannelIcloudStorageSync();

  /// The default instance of [IcloudStorageSyncPlatform] to use.
  ///
  /// Defaults to [MethodChannelIcloudStorageSync].
  static IcloudStorageSyncPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IcloudStorageSyncPlatform] when
  /// they register themselves.
  static set instance(IcloudStorageSyncPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Gathers all the files' metadata from the iCloud container.
  ///
  /// [containerId] is the iCloud Container Id.
  /// [onUpdate] is an optional callback for when the list of files is updated.
  Future<List<ICloudFile>> gather({
    required String containerId,
    StreamHandler<List<ICloudFile>>? onUpdate,
  }) async {
    throw UnimplementedError('gather() has not been implemented.');
  }

  /// Retrieves cloud files for a specific container.
  Future getCloudFiles({required String containerId}) {
    throw UnimplementedError('getCloudFiles() has not been implemented.');
  }

  /// Uploads a local file to iCloud.
  ///
  /// [containerId] is the iCloud Container Id.
  /// [filePath] is the full path of the local file.
  /// [destinationRelativePath] is the relative path for storing in iCloud.
  /// [onProgress] is an optional callback to track upload progress.
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
    StreamHandler<double>? onProgress,
  }) async {
    throw UnimplementedError('upload() has not been implemented.');
  }

  /// Downloads a file from iCloud.
  ///
  /// [containerId] is the iCloud Container Id.
  /// [relativePath] is the relative path of the file on iCloud.
  /// [destinationFilePath] is the full path to save the file locally.
  /// [onProgress] is an optional callback to track download progress.
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
    StreamHandler<double>? onProgress,
  }) async {
    throw UnimplementedError('download() has not been implemented.');
  }

  /// Deletes a file from the iCloud container.
  ///
  /// [containerId] is the iCloud Container Id.
  /// [relativePath] is the relative path of the file on iCloud.
  Future<void> delete({
    required String containerId,
    required String relativePath,
  }) async {
    throw UnimplementedError('delete() has not been implemented.');
  }

  /// Moves a file within the iCloud container.
  ///
  /// [containerId] is the iCloud Container Id.
  /// [fromRelativePath] is the current relative path of the file.
  /// [toRelativePath] is the new relative path for the file.
  Future<void> move({
    required String containerId,
    required String fromRelativePath,
    required String toRelativePath,
  }) async {
    throw UnimplementedError('move() has not been implemented.');
  }
}
