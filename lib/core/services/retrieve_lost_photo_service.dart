import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/services/insert_file_to_db_service.dart';
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
    final ImagePicker picker = ImagePicker();

    try {
      final LostDataResponse response = await picker.retrieveLostData();
      if (response.isEmpty) return;

      final List<XFile>? files = response.files;
      for (XFile file in files ?? []) {
        InsertFileToDbService.insertImage(file, await file.readAsBytes());
      }
    } on PlatformException catch (e, s) {
      AppLogger.error("RetrieveLostData#_getLostData error: ${e.message}", stackTrace: s);
    } catch (e, s) {
      AppLogger.error("RetrieveLostData#_getLostData unknown error: $e", stackTrace: s);
    }
  }
}
