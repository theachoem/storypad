import 'package:storypad/core/remote_storage_clients/base_storage_client.dart';
import 'package:storypad/core/remote_storage_clients/google_drive_storage_client.dart';

class BackupService {
  List<BaseStorageClient> enabledClients = [];

  final List<BaseStorageClient> _clients = [
    GoogleDriveStorageClient(),
  ];

  Future<void> load() async {
    for (BaseStorageClient client in _clients) {
      enabledClients.add(client);
    }
  }
}
