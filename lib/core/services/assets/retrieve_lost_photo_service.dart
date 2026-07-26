import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/services/assets/app_file_picker_service.dart';
import 'package:storypad/core/services/assets/insert_file_to_db_service.dart';
import 'package:storypad/core/services/assets/video_compression_service.dart';
import 'package:storypad/core/storages/device_preferences_storage.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

/// Checks and recovers any lost image data from the image picker (e.g. when the app was killed during photo capture).
///
/// This runs when user open image picker to retrieve pending photos and save them
/// to the database, ensuring no user content is lost.
///
/// Note: This is only applicable on Android.
/// https://pub.dev/packages/image_picker#android
class RetrieveLostPhotoService {
  static Future<void> call() async {
    if (!Platform.isAndroid) return;
    await _getLostData();
  }

  static Future<void> _getLostData() async {
    try {
      final LostDataResponse response = await AppFilePickerService.retrieveLostData();
      if (response.isEmpty) return;

      final List<XFile>? files = response.files;
      for (XFile file in files ?? []) {
        if (response.type == RetrieveType.video) {
          // The only path that reaches an insert without going through
          // `AppFilePickerService`, so it has to compress by hand -- these are
          // raw recordings the picker never got to hand back. No context here
          // (and nobody watching), so no spinner: it just runs unattended.
          final compression = DevicePreferencesStorage.appInstance.preferences.assetCompression;
          final compressed = await VideoCompressionService.compress(file, compression) ?? file;
          InsertFileToDbService.insertVideo(compressed);
        } else {
          InsertFileToDbService.insertImage(file, await file.readAsBytes());
        }
      }
    } on PlatformException catch (e, s) {
      AppLogger.error("RetrieveLostData#_getLostData error: ${e.message}", stackTrace: s);
    } catch (e, s) {
      AppLogger.error("RetrieveLostData#_getLostData unknown error: $e", stackTrace: s);
    }
  }
}
