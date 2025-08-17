import 'package:storypad/core/repositories/backup_repository.dart';

class BackupRepositoryInitializer {
  static Future<void> call() async {
    // Initialize the GoogleSignIn instance first
    await BackupRepository.appInstance.googleDriveClient.initialize();
    
    // Then load user locally
    await BackupRepository.appInstance.googleDriveClient.loadUserLocally();
  }
}
