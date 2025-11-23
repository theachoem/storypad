import 'package:storypad/core/services/firestore_storage_service.dart';

class FirestoreStorageCleanupInitializer {
  static void call() {
    FirestoreStorageService.instance.cleanupUnusedFiles();
  }
}
