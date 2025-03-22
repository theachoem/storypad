import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_image.dart';
import 'package:path/path.dart' as path;

class SpImagePickerBottomSheet extends BaseBottomSheet {
  const SpImagePickerBottomSheet({
    required this.assets,
  });

  final List<AssetDbModel> assets;

  static Future<void> showQuillPicker<T>({
    required BuildContext context,
    required QuillController controller,
  }) async {
    final assets = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);
    if (!context.mounted) return;

    final asset = await SpImagePickerBottomSheet(
      assets: assets,
    ).show(context: context);

    if (asset is AssetDbModel) {
      final index = controller.selection.baseOffset;
      final length = controller.selection.extentOffset - index;

      controller.replaceText(index, length, BlockEmbed.image(asset.link), null);
      controller.moveCursorToPosition(index + 1);

      AnalyticsService.instance.logInsertNewPhoto();
    }
  }

  Future<void> _insertFromPhotoLibrary(BuildContext context) async {
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

      if (savedAsset != null && context.mounted) {
        Navigator.maybePop(context, savedAsset);
      }
    }
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return LayoutBuilder(builder: (context, constraints) {
          return buildScaffold(context, constraints, scrollController);
        });
      },
    );
  }

  Widget buildScaffold(BuildContext context, BoxConstraints constraints, ScrollController scrollController) {
    return Scaffold(
      appBar: AppBar(title: Text("$kAppName Library")),
      body: buildBody(
        context: context,
        constraints: constraints,
        scrollController: scrollController,
      ),
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
                  onPressed: () => _insertFromPhotoLibrary(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody({
    required BuildContext context,
    required BoxConstraints constraints,
    required ScrollController scrollController,
  }) {
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
