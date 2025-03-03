import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path/path.dart' as path;
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/custom_embed/sp_image.dart';

class ImagePickerService {
  final QuillController controller;

  ImagePickerService({
    required this.controller,
  });

  Future<void> showSheet(BuildContext context) async {
    final assets = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);

    if (!context.mounted) return;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    final asset = await showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      builder: (context) {
        double height = MediaQuery.of(context).size.height;

        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: (height - statusBarHeight) / height,
          builder: (context, controller) {
            return _PhotoSheet(
              assets: assets,
              scrollController: controller,
            );
          },
        );
      },
    );

    if (asset is AssetDbModel) {
      final index = controller.selection.baseOffset;
      final length = controller.selection.extentOffset - index;

      controller.replaceText(index, length, BlockEmbed.image(asset.link), null);
      controller.moveCursorToPosition(index + 1);
    }
  }
}

// TODO: extract this

class _PhotoSheet extends StatelessWidget {
  const _PhotoSheet({
    required this.assets,
    required this.scrollController,
  });

  final List<AssetDbModel> assets;
  final ScrollController scrollController;

  Future<void> insertFromPhotoLibrary(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result?.files.isNotEmpty == true) {
      final pickedFile = result!.xFiles.first;
      final now = DateTime.now();

      String extension = path.extension(pickedFile.path);

      // We need to store picked file to somewhere we can manage.
      File newFile = File("${kApplicationDirectory.path}/images/${now.millisecondsSinceEpoch}$extension");
      await newFile.parent.create(recursive: true);

      if (Platform.isAndroid) {
        newFile = await newFile.writeAsBytes(await pickedFile.readAsBytes());
      } else {
        await File(pickedFile.path).rename(newFile.path);
      }

      await File(pickedFile.path).parent.delete(recursive: true);
      final asset = AssetDbModel.fromLocalPath(
        id: now.millisecondsSinceEpoch,
        localPath: newFile.path,
      );

      final savedAsset = await asset.save();

      AnalyticsService.instance.logInsertNewPhoto();

      if (savedAsset != null && context.mounted) {
        Navigator.maybePop(context, savedAsset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(title: Text("$kAppName Library")),
        body: buildBody(context, constraints),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            Container(
              padding: EdgeInsets.only(
                left: 8.0,
                top: 8.0,
                bottom: MediaQuery.of(context).padding.bottom + 8.0,
                right: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.add_a_photo),
                    label: Text("Insert from Device"),
                    onPressed: () => insertFromPhotoLibrary(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildBody(BuildContext context, BoxConstraints constraints) {
    if (assets.isEmpty) {
      return Center(
        child: Text(
          "Added photos will appear here",
          textAlign: TextAlign.center,
          style: TextTheme.of(context).bodyLarge,
        ),
      );
    }

    return MasonryGridView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.0)
          .copyWith(top: 16.0, bottom: MediaQuery.of(context).padding.bottom + 16.0),
      itemCount: assets.length,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth ~/ 120),
      itemBuilder: (BuildContext context, int index) {
        final asset = assets[index];
        return GestureDetector(
          onTap: () => Navigator.pop(context, asset),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SpImage(
              link: asset.link,
              width: double.infinity,
              height: null,
            ),
          ),
        );
      },
    );
  }
}
