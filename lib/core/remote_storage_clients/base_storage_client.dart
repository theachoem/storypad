import 'dart:async';

abstract class BaseStorageClient {
  String get id;

  bool get supportSignOut;

  Future<void> authenticate();

  Future<void> signOut() async {}

  FutureOr<bool> isAuthenticated();

  Future<void> delete({
    Folder? remoteFileFolder,
    required String remoteFileName,
  });

  Future<void> download({
    Folder? remoteFileFolder,
    required String remoteFileName,
    required String destinationFilePath,
  });

  Future<List<RemoteFile>> list([Folder? folder]);

  Future<void> upload({
    required String sourceFilePath,
    Folder? remoteFileFolder,
    required String remoteFileName,
  });
}

enum Folder {
  stories,
  images,
  audio,
  videos,
  documents,
}

class RemoteFile {
  final String? title;
  final String path; // remote path, e.g. "documents/journal.json"
  final int? bytesSize; // file size in bytes
  final DateTime? lastSyncDate; // last modified timestamp

  RemoteFile({
    required this.path,
    this.title,
    this.bytesSize,
    this.lastSyncDate,
  });
}
