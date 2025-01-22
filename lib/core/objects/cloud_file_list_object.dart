import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class CloudFileListObject {
  final List<CloudFileObject> files;
  final String? nextPageToken;

  CloudFileListObject({
    required this.files,
    required this.nextPageToken,
  });

  factory CloudFileListObject.fromGoogleDrive(drive.FileList fileList) {
    List<CloudFileObject> list = [];

    for (drive.File file in fileList.files!) {
      if (file.id == null) continue;
      list.add(CloudFileObject.fromGoogleDrive(file));
    }

    return CloudFileListObject(
      files: list,
      nextPageToken: fileList.nextPageToken,
    );
  }
}
