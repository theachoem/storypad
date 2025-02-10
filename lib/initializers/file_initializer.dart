import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:storypad/core/constants/app_constants.dart';

class FileInitializer {
  static Future<void> call() async {
    kSupportDirectory = await getApplicationSupportDirectory();
    kApplicationDirectory =
        (Platform.isAndroid ? await getExternalStorageDirectory() : null) ?? await getApplicationDocumentsDirectory();
  }
}
