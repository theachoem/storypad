import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';

class CloudStorageInitializer {
  static void call() {
    cleanup();
  }

  static void cleanup() {
    CloudStorageService.instance.cleanupUnusedFiles();
  }
}
