import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart' as path;
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_image.dart';

class SpImagePickerBottomSheet extends BaseBottomSheet {
  const SpImagePickerBottomSheet({
    required this.assets,
  });

  @override
  bool get fullScreen => true;

  final List<AssetDbModel> assets;

  static Future<void> showQuillPicker<T>({
    required BuildContext context,
    required QuillController controller,
  }) async {
    final assets = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);
    if (!context.mounted) return;

    final pickAssets = await SpImagePickerBottomSheet(
      assets: assets,
    ).show(context: context);

    if (pickAssets is List<AssetDbModel>) {
      for (AssetDbModel pickAsset in pickAssets) {
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;

        controller.replaceText(index, length, BlockEmbed.image(pickAsset.link), null);
        controller.moveCursorToPosition(index + 1);
      }

      AnalyticsService.instance.logInsertNewPhoto();
    }
  }

  Future<void> _insertFromPhotoLibrary(BuildContext context) async {
    FilePickerResult? result;

    try {
      result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    } catch (e) {
      debugPrint(e.toString());
    }

    if (result?.files.isNotEmpty == true) {
      List<AssetDbModel> saveAssets = [];

      for (var file in result!.files) {
        if (file.bytes == null) continue;

        final now = DateTime.now();
        String extension = path.extension(file.xFile.path);

        // We need to store picked file to somewhere we can manage.
        File newFile = File("${kSupportDirectory.path}/images/${now.millisecondsSinceEpoch}$extension")
          ..createSync(recursive: true);
        newFile = await newFile.writeAsBytes(file.bytes!);
        if (File(file.xFile.path).parent.existsSync()) File(file.xFile.path).parent.deleteSync(recursive: true);

        final asset = AssetDbModel.fromLocalPath(
          id: now.millisecondsSinceEpoch,
          localPath: newFile.path,
        );

        final savedAsset = await asset.save();
        if (savedAsset != null) saveAssets.add(savedAsset);
      }

      if (context.mounted && saveAssets.isNotEmpty) {
        Navigator.maybePop(context, saveAssets);
      }
    }
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return buildScaffold(context);
    } else {
      double maxChildSize = 1 - View.of(context).viewPadding.top / MediaQuery.of(context).size.height;
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: maxChildSize,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildScaffold(context),
          );
        },
      );
    }
  }

  Widget buildScaffold(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("$kAppName Library"),
          automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
          actions: [
            if (CupertinoSheetRoute.hasParentSheet(context))
              CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
          ],
        ),
        body: buildBody(
          context: context,
          constraints: constraints,
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
                    icon: const Icon(SpIcons.addPhoto),
                    label: const Text("Insert from Device"),
                    onPressed: () => _insertFromPhotoLibrary(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildBody({
    required BuildContext context,
    required BoxConstraints constraints,
  }) {
    if (assets.isEmpty) {
      return Center(
        child: Text(
          tr('page.image_picker.empty_message'),
          textAlign: TextAlign.center,
          style: TextTheme.of(context).bodyLarge,
        ),
      );
    }

    return MasonryGridView.builder(
      controller: PrimaryScrollController.maybeOf(context),
      padding: const EdgeInsets.symmetric(horizontal: 16.0)
          .copyWith(top: 16.0, bottom: MediaQuery.of(context).padding.bottom + 16.0),
      itemCount: assets.length,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth ~/ 120),
      itemBuilder: (BuildContext context, int index) {
        final asset = assets[index];
        return GestureDetector(
          onTap: () => Navigator.pop(context, [asset]),
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
