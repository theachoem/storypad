import 'dart:io' as io;

import 'package:storypad/core/objects/cloud_file_list_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';

class GoogleDriveClientService {
  Future<CloudFileObject?> getLastestBackupFile() async {
    return null;
  }

  Future<String?> getFileContent(CloudFileObject lastestCloudFile) async {
    return '';
  }

  Future<CloudFileObject?> uploadFile(String fileNameWithExtention, io.File file, {String? folderName}) async {
    return null;
  }

  Future<CloudFileListObject?> fetchAllCloudFiles() async {
    return null;
  }

  Future<bool> deleteCloudFile(CloudFileObject file) async {
    return true;
  }
}
