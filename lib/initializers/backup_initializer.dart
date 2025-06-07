import 'package:storypad/core/repositories/backup_repository.dart';

class BackupRepositoryInitializer {
  static Future<void> call() async {
    await BackupRepository.appInstance.googleDriveClient.loadUserLocally();
  }
}
