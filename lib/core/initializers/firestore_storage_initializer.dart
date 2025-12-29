import 'package:storypad/core/services/firestore_storage_service.dart';

class FirestoreStorageInitializer {
  static Future<void> call() async {
    await FirestoreStorageService.instance.loadHash();
    cleanup();
  }

  static void cleanup() {
    FirestoreStorageService.instance.cleanupUnusedFiles();
  }
}
