import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path/path.dart' as path;
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/initializers/file_initializer.dart';

class QuillImageService {
  final QuillController controller;

  QuillImageService({
    required this.controller,
  });

  Future<void> add(BuildContext context) async {
    final assets = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);
    final List<AssetDbModel> validAssets = assets.where((e) {
      return e.localFile != null;
    }).toList();

    if (!context.mounted) return;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    final result = await showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (context) {
        double height = MediaQuery.of(context).size.height;

        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: (height - statusBarHeight) / height,
          builder: (context, controller) {
            return MasonryGridView.builder(
              controller: controller,
              padding:
                  EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16.0),
              itemCount: validAssets.length,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              itemBuilder: (BuildContext context, int index) {
                final asset = validAssets[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, asset),
                  child: Image.file(
                    asset.localFile!,
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result is AssetDbModel) {
      String assetRef = "storypad://${result.id}";

      final index = controller.selection.baseOffset;
      final length = controller.selection.extentOffset - index;

      controller.replaceText(index, length, BlockEmbed.image(assetRef), null);
      controller.moveCursorToPosition(index + 1);
    }
  }

  Future<void> show() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.xFiles.isNotEmpty) {
      final pickedFile = result.xFiles.first;
      final now = DateTime.now();

      String extension = path.extension(pickedFile.path);

      File newFile = File("${kApplicationDirectory.path}/images/${now.millisecondsSinceEpoch}$extension");
      await newFile.parent.create(recursive: true);
      await File(pickedFile.path).rename(newFile.path);
      await File(pickedFile.path).parent.delete(recursive: true);

      final asset = AssetDbModel.fromLocalPath(
        id: now.millisecondsSinceEpoch,
        localPath: newFile.path,
      );

      final savedAsset = await asset.save();
      if (savedAsset != null) {
        String assetRef = "storypad://${savedAsset.id}";

        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;

        controller.replaceText(index, length, BlockEmbed.image(assetRef), null);
        controller.moveCursorToPosition(index + 1);
      }
    }
  }
}
