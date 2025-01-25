import 'dart:io';
import 'package:path_provider/path_provider.dart';

late final Directory kSupportDirectory;
late final Directory kApplicationDirectory;

class FileInitializer {
  static Future<void> call() async {
    kSupportDirectory = await getApplicationSupportDirectory();

    if (Platform.isAndroid) {
      kApplicationDirectory = await getExternalStorageDirectory().then(
        (data) => data ?? getApplicationDocumentsDirectory(),
      );
    } else {
      kApplicationDirectory = await getApplicationDocumentsDirectory();
    }
  }
}
