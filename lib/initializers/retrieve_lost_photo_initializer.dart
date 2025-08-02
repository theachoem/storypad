import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/services/insert_file_to_db_service.dart';

/// Checks and recovers any lost image data from the image picker (e.g. when the app was killed during photo capture).
///
/// This runs on app launch to automatically retrieve pending photos and save them
/// to the database, ensuring no user content is lost.
///
/// Note: This is only applicable on Android.
/// https://pub.dev/packages/image_picker#android
class RetrieveLostPhotoInitializer {
  static Future<void> call() async {
    if (Platform.isAndroid) {
      await _getLostData();
    }
  }

  static Future<void> _getLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) return;

    final List<XFile>? files = response.files;
    for (XFile file in files ?? []) {
      InsertFileToDbService.insert(file, await file.readAsBytes());
    }
  }
}
