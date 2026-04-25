import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:storypad/core/services/cloud_storage/adaptors/base_cloud_storage_adaptor.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

class FirebaseCloudStorageAdaptor extends BaseCloudStorageAdaptor {
  // 20mb — validated during upload in bin/firebase_admin/upload_files_to_firestore_storages.js
  static const int _maxDownloadSize = 20 * 1024 * 1024;

  final _storageRef = FirebaseStorage.instance.ref();

  @override
  Future<Uint8List?> downloadBytes(String hashPath) async {
    try {
      final content = await _storageRef.child(hashPath).getData(_maxDownloadSize);
      return content;
    } on FirebaseException catch (e, s) {
      AppLogger.error(
        'FirebaseCloudStorageAdaptor#downloadBytes code: ${e.code}, message: ${e.message}',
        stackTrace: s,
      );
      if (e.code == 'unauthorized') {
        throw CloudStorageUnauthorizedException('Firebase unauthorized: $hashPath');
      }
      return null;
    } catch (e, s) {
      AppLogger.error('FirebaseCloudStorageAdaptor#downloadBytes: $e', stackTrace: s);
      return null;
    }
  }

  @override
  Future<String?> getDownloadUrl(String hashPath) async {
    try {
      return await _storageRef.child(hashPath).getDownloadURL();
    } on FirebaseException catch (e, s) {
      AppLogger.error(
        'FirebaseCloudStorageAdaptor#getDownloadUrl code: ${e.code}, message: ${e.message}',
        stackTrace: s,
      );
      return null;
    } catch (e, s) {
      AppLogger.error('FirebaseCloudStorageAdaptor#getDownloadUrl: $e', stackTrace: s);
      return null;
    }
  }
}
