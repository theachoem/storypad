import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';

class CloudStorageInitializer {
  static Future<void> call() async {
    await CloudStorageService.instance.loadHash();
    cleanup();
  }

  static void cleanup() {
    CloudStorageService.instance.cleanupUnusedFiles();
  }
}
