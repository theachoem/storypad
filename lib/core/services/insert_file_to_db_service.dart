import 'dart:io' show File;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart' as path show extension;

class InsertFileToDbService {
  static Future<AssetDbModel?> insert(XFile file, Uint8List fileBytes) async {
    final now = DateTime.now();
    String extension = path.extension(file.path);

    // We need to store picked file to somewhere we can manage.
    File newFile = File("${kSupportDirectory.path}/images/${now.millisecondsSinceEpoch}$extension")
      ..createSync(recursive: true);
    newFile = await newFile.writeAsBytes(fileBytes);
    if (File(file.path).parent.existsSync()) File(file.path).parent.deleteSync(recursive: true);

    final asset = AssetDbModel.fromLocalPath(
      id: now.millisecondsSinceEpoch,
      localPath: newFile.path,
    );

    return asset.save();
  }
}
