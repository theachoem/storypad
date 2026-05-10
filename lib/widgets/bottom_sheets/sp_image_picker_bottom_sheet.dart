import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/rich_text/rich_text.dart';
import 'package:storypad/core/services/assets/app_file_picker_service.dart';
import 'package:storypad/core/services/assets/retrieve_lost_photo_service.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/assets/insert_file_to_db_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_image.dart';

class SpImagePickerBottomSheet extends BaseBottomSheet {
  const SpImagePickerBottomSheet({
    required this.assets,
  });

  @override
  bool get fullScreen => true;

  final List<AssetDbModel> assets;

  static Future<void> showImagePicker({
    required BuildContext context,
    required RichTextController controller,
    required ImageSource source,
  }) async {
    return SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () async {
        final compression = context.read<DevicePreferencesProvider>().preferences.assetCompression;
        final XFile? photo = await AppFilePickerService.pickImage(
          source: source,
          compression: compression,
        );
        if (photo == null) return;

        AssetDbModel? tookAsset = await InsertFileToDbService.insertImage(photo, await photo.readAsBytes());
        if (tookAsset == null) return;

        editorAdapter.insertImage(
          controller: controller,
          imagePath: tookAsset.relativeLocalFilePath,
        );

        if (source == ImageSource.camera) {
          AnalyticsService.instance.logTakePhoto();
        } else {
          AnalyticsService.instance.logInsertNewPhoto();
        }
      },
    );
  }

  static Future<void> showQuillPicker<T>({
    required BuildContext context,
    required RichTextController controller,
  }) async {
    await RetrieveLostPhotoService.call();

    final assets = await AssetDbModel.db
        .where(filters: {'type': AssetType.image})
        .then((e) => e?.items ?? <AssetDbModel>[]);
    if (!context.mounted) return;

    final pickAssets = await SpImagePickerBottomSheet(
      assets: assets,
    ).show(context: context);

    if (pickAssets is List<AssetDbModel> && pickAssets.isNotEmpty) {
      // Image embed support multiple images by joining paths with '|', and parsing them in the embed builder.
      // See docs/features/album-embed.md for details.
      final imagePath = pickAssets.map((a) => a.relativeLocalFilePath).join('|');

      editorAdapter.insertImage(
        controller: controller,
        imagePath: imagePath,
      );

      AnalyticsService.instance.logInsertNewPhoto();
    }
  }

  static Future<List<AssetDbModel>?> showAlbumPicker({
    required BuildContext context,
  }) async {
    await RetrieveLostPhotoService.call();

    final assets = await AssetDbModel.db
        .where(filters: {'type': AssetType.image})
        .then((e) => e?.items ?? <AssetDbModel>[]);
    if (!context.mounted) return null;

    final result = await SpImagePickerBottomSheet(
      assets: assets,
    ).show(context: context);

    return result is List<AssetDbModel> ? result : null;
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return _Content(params: this);
    } else {
      double maxChildSize = 1 - View.of(context).viewPadding.top / MediaQuery.of(context).size.height;
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: maxChildSize,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: _Content(params: this),
          );
        },
      );
    }
  }
}

class _Content extends StatefulWidget {
  const _Content({
    required this.params,
  });

  final SpImagePickerBottomSheet params;

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  List<AssetDbModel> get assets => widget.params.assets;

  Map<int, AssetDbModel> selectedAssets = {};

  Future<void> _insertFromPhotoLibrary(BuildContext context) async {
    FilePickerResult? result;

    try {
      result = await SpAppLockWrapper.disableAppLockIfHas(
        context,
        callback: () {
          final compression = context.read<DevicePreferencesProvider>().preferences.assetCompression;

          return AppFilePickerService.pickImageFiles(
            allowMultiple: true,
            compression: compression,
          );
        },
      );
    } catch (e) {
      debugPrint(e.toString());
    }

    if (result?.files.isNotEmpty == true) {
      List<AssetDbModel> saveAssets = [];

      for (var file in result!.files) {
        if (file.bytes == null) continue;

        final savedAsset = await InsertFileToDbService.insertImage(file.xFile, file.bytes!);
        if (savedAsset != null) saveAssets.add(savedAsset);
      }

      if (context.mounted && saveAssets.isNotEmpty) {
        Navigator.maybePop(context, saveAssets);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("$kAppName Library"),
            automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
            actions: [
              if (CupertinoSheetRoute.hasParentSheet(context))
                CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
            ],
          ),
          body: buildBody(
            context: context,
            constraints: constraints,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 8.0,
                  top: 8.0,
                  bottom: MediaQuery.of(context).padding.bottom + 8.0,
                  right: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8.0,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(SpIcons.addPhoto),
                      label: Text(tr("button.insert_from_device")),
                      onPressed: () => _insertFromPhotoLibrary(context),
                    ),
                    FilledButton(
                      onPressed: selectedAssets.isNotEmpty
                          ? () => Navigator.maybePop(context, selectedAssets.values.toList())
                          : null,
                      child: Text(tr("button.done")),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      controller: PrimaryScrollController.maybeOf(context),
      child: MasonryGridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        addAutomaticKeepAlives: false,
        controller: PrimaryScrollController.maybeOf(context),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
        ).copyWith(top: 16.0, bottom: MediaQuery.of(context).padding.bottom + 16.0),
        itemCount: assets.length,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth ~/ 120),
        itemBuilder: (BuildContext context, int index) {
          final asset = assets[index];

          return GestureDetector(
            onTap: () {
              if (selectedAssets.containsKey(asset.id)) {
                selectedAssets.remove(asset.id);
              } else {
                selectedAssets[asset.id] = asset;
              }
              setState(() {});
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SpImage(
                    link: asset.relativeLocalFilePath,
                    width: double.infinity,
                    height: 120,
                  ),
                ),
                if (selectedAssets.containsKey(asset.id)) buildSelectedCheck(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildSelectedCheck() {
    final Color foregroundColor = Colors.white.withValues(alpha: 0.7);

    return Positioned(
      key: ValueKey('$foregroundColor'),
      top: 8,
      right: 8,
      child: SpFadeIn.fromBottom(
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            SpIcons.checkCircle,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}
