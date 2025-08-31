import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:icloud_storage_sync/models/exceptions.dart';
import 'package:icloud_storage_sync/models/icloud_file.dart';
import 'package:icloud_storage_sync/models/icloud_file_download.dart';

import 'icloud_storage_sync_platform_interface.dart';

class IcloudStorageSync {
  Future<String?> getPlatformVersion() {
    return IcloudStorageSyncPlatform.instance.getPlatformVersion();
  }

  /// Gathers metadata for all files in the specified iCloud container.
  ///
  /// [containerId] The ID of the iCloud container to query.
  /// [onUpdate] An optional callback that will be triggered when the file list is updated.
  ///
  /// Returns a Future that resolves to a List of [ICloudFile] objects.
  Future<List<ICloudFile>> gather({
    required String containerId,
    StreamHandler<List<ICloudFile>>? onUpdate,
  }) async {
    return await IcloudStorageSyncPlatform.instance.gather(
      containerId: containerId,
      onUpdate: onUpdate,
    );
  }

  /// Retrieves a list of [CloudFiles] from the specified iCloud container.
  ///
  /// This method combines the metadata from [gather] with the actual file paths.
  ///
  /// [containerId] The ID of the iCloud container to query.
  ///
  /// Returns a Future that resolves to a List of [CloudFiles] objects.
  Future<List<CloudFiles>> getCloudFiles({required String containerId}) async {
    try {
      final response = await gather(containerId: containerId);
      final path = (await IcloudStorageSyncPlatform.instance.getCloudFiles(
        containerId: containerId,
      )) as List;
      return await response.toFile(
          path.map((e) => e.toString()).toList(), containerId);
    } on PlatformException catch (e) {
      debugPrint("Failed to get files from iCloud Drive: ${e.message}");
      return [];
    }
  }

  /// Uploads a local file to iCloud.
  ///
  /// [containerId] The ID of the iCloud container to upload to.
  /// [filePath] The full path of the local file to upload.
  /// [destinationRelativePath] Optional. The relative path in iCloud where the file should be stored.
  /// [onProgress] Optional callback to track upload progress.
  ///
  /// Throws [InvalidArgumentException] if the file path or destination path is invalid.
  Future<void> upload({
    required String containerId,
    required String filePath,
    String? destinationRelativePath,
    StreamHandler<double>? onProgress,
  }) async {
    if (filePath.trim().isEmpty) {
      throw InvalidArgumentException('invalid filePath');
    }

    final destination = destinationRelativePath ?? filePath.split('/').last;

    if (!_validateRelativePath(destination)) {
      throw InvalidArgumentException('invalid destination relative path');
    }

    await IcloudStorageSyncPlatform.instance.upload(
      containerId: containerId,
      filePath: filePath,
      destinationRelativePath: destination,
      onProgress: onProgress,
    );
  }

  Future<void> uploadMultipleFileToICloud(
      {required String containerId, required List<File> files}) async {
    for (var file in files) {
      await upload(
        containerId: containerId,
        filePath: file.path,
        onProgress: (progress) async {
          final firstProgress = await progress.first;
          final lastProgress = await progress.last;
          debugPrint(
              "File: ${file.path}, First Progress: $firstProgress, Last Progress: $lastProgress");
          // Update UI or state with progress here
        },
      );
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  /// Downloads a file from iCloud to the local device.
  ///
  /// [containerId] The ID of the iCloud container to download from.
  /// [relativePath] The relative path of the file in iCloud.
  /// [destinationFilePath] The full path where the file should be saved locally.
  /// [onProgress] Optional callback to track download progress.
  ///
  /// Throws [InvalidArgumentException] if the relative path or destination file path is invalid.
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
    StreamHandler<double>? onProgress,
  }) async {
    if (!_validateRelativePath(relativePath)) {
      throw InvalidArgumentException('invalid relativePath');
    }
    if (destinationFilePath.trim().isEmpty ||
        destinationFilePath[destinationFilePath.length - 1] == '/') {
      throw InvalidArgumentException('invalid destinationFilePath');
    }

    await IcloudStorageSyncPlatform.instance.download(
      containerId: containerId,
      relativePath: relativePath,
      destinationFilePath: destinationFilePath,
      onProgress: onProgress,
    );
  }

  /// Deletes a file from the iCloud container.
  ///
  /// [containerId] The ID of the iCloud container.
  /// [relativePath] The relative path of the file to delete.
  ///
  /// Throws [InvalidArgumentException] if the relative path is invalid.
  /// May throw [PlatformException] if the file is not found.
  Future<void> delete({
    required String containerId,
    required String relativePath,
  }) async {
    if (!_validateRelativePath(Uri.decodeComponent(relativePath))) {
      throw InvalidArgumentException('invalid relativePath');
    }

    await IcloudStorageSyncPlatform.instance.delete(
      containerId: containerId,
      relativePath: Uri.decodeComponent(relativePath),
    );
  }

  Future<void> deleteMultipleFileToICloud(
      {required String containerId,
      required List<String> relativePathList}) async {
    for (var path in relativePathList) {
      debugPrint("path ------ ${Uri.decodeComponent(path)}");
      if (!_validateRelativePath(Uri.decodeComponent(path))) {
        throw InvalidArgumentException('invalid relativePath');
      }
      await IcloudStorageSyncPlatform.instance.delete(
        containerId: containerId,
        relativePath: Uri.decodeComponent(path),
      );
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  /// Moves a file from one location to another within the iCloud container.
  ///
  /// [containerId] The ID of the iCloud container.
  /// [fromRelativePath] The current relative path of the file.
  /// [toRelativePath] The new relative path for the file.
  ///
  /// Throws [InvalidArgumentException] if either path is invalid.
  /// May throw [PlatformException] if the file is not found.
  static Future<void> move({
    required String containerId,
    required String fromRelativePath,
    required String toRelativePath,
  }) async {
    if (!_validateRelativePath(Uri.decodeComponent(fromRelativePath)) ||
        !_validateRelativePath(Uri.decodeComponent(toRelativePath))) {
      throw InvalidArgumentException('invalid relativePath');
    }

    await IcloudStorageSyncPlatform.instance.move(
      containerId: containerId,
      fromRelativePath: Uri.decodeComponent(fromRelativePath),
      toRelativePath: Uri.decodeComponent(toRelativePath),
    );
  }

  /// Renames a file in the iCloud container.
  ///
  /// [containerId] The ID of the iCloud container.
  /// [relativePath] The current relative path of the file.
  /// [newName] The new name for the file (not a full path).
  ///
  /// Throws [InvalidArgumentException] if the relative path or new name is invalid.
  /// May throw [PlatformException] if the file is not found.
  Future<void> rename({
    required String containerId,
    required String relativePath,
    required String newName,
  }) async {
    if (!_validateRelativePath(Uri.decodeComponent(relativePath))) {
      throw InvalidArgumentException('invalid relativePath');
    }

    if (!_validateFileName(newName)) {
      throw InvalidArgumentException('invalid newName');
    }

    await move(
      containerId: containerId,
      fromRelativePath: Uri.decodeComponent(relativePath),
      toRelativePath: Uri.decodeComponent(relativePath)
              .substring(0, relativePath.lastIndexOf('/') + 1) +
          newName,
    );
  }

  /// Replace an existing file in the iCloud container with new content.
  ///
  /// This function performs an atomic update operation by:
  /// 1. Deleting the existing file at [relativePath]
  /// 2. Uploading the new file from [updatedFilePath]
  /// 3. Waiting for the operation to complete
  ///
  /// Parameters:
  /// - [containerId]: The ID of the iCloud container where the file exists
  /// - [updatedFilePath]: The local path to the new version of the file
  /// - [relativePath]: The relative path of the existing file in iCloud
  ///
  /// Throws:
  /// - [InvalidArgumentException] if the relative path is invalid
  /// - [InvalidArgumentException] if the updated file path is empty
  /// - May throw platform-specific exceptions during delete or upload operations
  ///
  /// Note: There is a 2-second delay after the operation to ensure iCloud sync completion
  Future<void> replace({
    required String containerId,
    required String updatedFilePath,
    required String relativePath,
  }) async {
    // Validate the iCloud relative path format
    if (!_validateRelativePath(Uri.decodeComponent(relativePath))) {
      throw InvalidArgumentException('invalid relativePath');
    }

    // Ensure the new file path is not empty
    if (updatedFilePath.isEmpty) {
      throw InvalidArgumentException('invalid updatedFilePath');
    }

    // Delete the existing file from iCloud
    await delete(containerId: containerId, relativePath: relativePath);

    // Upload the new version of the file
    await upload(
      containerId: containerId,
      filePath: updatedFilePath,
    );

    // Wait for iCloud sync to complete
    await Future.delayed(const Duration(seconds: 2));
  }

  /// Validates that a given path is a valid relative path.
  /// Each part of the path must be a valid file or directory name.
  static bool _validateRelativePath(String path) {
    final fileOrDirNames = path.split('/');
    if (fileOrDirNames.isEmpty) return false;

    return fileOrDirNames.every((name) => _validateFileName(name));
  }

  /// Validates that a given string is a valid file name.
  /// It must not contain '/' or ':', must not start with '.',
  /// and must be between 1 and 255 characters long.
  static bool _validateFileName(String name) => !(name.isEmpty ||
      name.length > 255 ||
      RegExp(r"([:/]+)|(^[.].*$)").hasMatch(name));
}
