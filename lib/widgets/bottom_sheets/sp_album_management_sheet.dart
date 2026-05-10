import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/assets/app_file_picker_service.dart';
import 'package:storypad/core/services/assets/insert_file_to_db_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_album_grid.dart';
import 'package:storypad/widgets/bottom_sheets/sp_image_picker_bottom_sheet.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_image.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';

class SpAlbumManagementSheet extends BaseBottomSheet {
  const SpAlbumManagementSheet({required this.paths});

  final List<String> paths;

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return _Content(paths: paths, bottomPadding: bottomPadding);
    } else {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: _Content(paths: paths, bottomPadding: bottomPadding),
          );
        },
      );
    }
  }
}

class _Content extends StatefulWidget {
  const _Content({required this.paths, required this.bottomPadding});

  final List<String> paths;
  final double bottomPadding;

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  late List<String> _paths;

  @override
  void initState() {
    super.initState();
    _paths = widget.paths.toSet().toList();
  }

  Future<void> _takePhoto(BuildContext context) async {
    final compression = context.read<DevicePreferencesProvider>().preferences.assetCompression;
    final XFile? photo = await SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () => AppFilePickerService.pickImage(
        source: ImageSource.camera,
        compression: compression,
      ),
    );

    if (photo == null) return;

    final AssetDbModel? tookAsset = await InsertFileToDbService.insertImage(photo, await photo.readAsBytes());
    if (tookAsset == null) return;

    if (mounted) {
      setState(() {
        _paths = {
          ..._paths,
          tookAsset.relativeLocalFilePath,
        }.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => Navigator.maybePop(context)),
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
              spacing: 8.0,
              children: [
                IconButton.outlined(
                  icon: Icon(SpIcons.camera, color: ColorScheme.of(context).primary),
                  onPressed: () => _takePhoto(context),
                ),
                IconButton.outlined(
                  icon: Icon(SpIcons.photo, color: ColorScheme.of(context).primary),
                  onPressed: () async {
                    final picked = await SpImagePickerBottomSheet.showAlbumPicker(context: context);
                    if (picked != null && picked.isNotEmpty) {
                      setState(() {
                        _paths = {
                          ..._paths,
                          ...picked.map((a) => a.relativeLocalFilePath),
                        }.toList();
                      });
                    }
                  },
                ),
                IconButton.filled(
                  icon: const Icon(SpIcons.save),
                  onPressed: () => Navigator.pop(context, _paths.toSet().toList()),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        scrollController: PrimaryScrollController.maybeOf(context),
        header: Padding(
          padding: const EdgeInsets.all(16.0).copyWith(top: 0.0),
          child: AnimatedSize(
            curve: Curves.ease,
            duration: Durations.medium1,
            child: AnimatedSwitcher(
              duration: Durations.medium1,
              child: SpAlbumGrid(
                key: ValueKey(_paths.join(",")),
                paths: _paths,
                onTap: (index) {
                  Feedback.forTap(context);
                  SpImagesViewer.fromString(
                    images: _paths,
                    initialIndex: index,
                    context: context,
                  ).show(context);
                },
              ),
            ),
          ),
        ),
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        itemCount: _paths.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _paths.removeAt(oldIndex);
            _paths.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final path = _paths[index];

          return ListTile(
            key: ValueKey("$runtimeType-$path"),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SpImage(link: path, width: 56, height: 56),
            ),
            title: Text(
              path.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_paths.length > 1)
                  IconButton(
                    icon: Icon(SpIcons.delete, color: ColorScheme.of(context).error),
                    onPressed: () => setState(() => _paths.removeAt(index)),
                  ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(SpIcons.dragIndicator),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
