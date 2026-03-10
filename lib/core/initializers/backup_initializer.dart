import 'package:storypad/providers/backup_provider.dart';

class BackupRepositoryInitializer {
  static Future<void> call() async {
    await BackupProvider.repoInstance.initialize();
  }
}
