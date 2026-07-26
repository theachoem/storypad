import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/device_volume_service.dart';
import 'package:storypad/core/services/duration_format_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/asset_db/sp_db_asset_loader.dart';
import 'package:storypad/widgets/asset_db/sp_db_image_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_asset_info_sheet.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_icons.dart';

part 'image_page_scaffold.dart';
part 'video_page_scaffold.dart';

const Color _foregroundColor = Colors.white;

/// A single page in [SpMediaViewer] -- either an image (with a resolved
/// [ImageProvider]) or a video (resolved lazily by [_VideoPageScaffold]
/// itself from [tag], the relative asset path).
class SpMediaViewerItem {
  final AssetType type;
  final String tag;
  final ImageProvider? provider;
  final String? alt;
  final double scale;
  final Widget Function(BuildContext, Image)? builder;

  /// Relative path (`images/{id}.jpg`, `videos/{id}.mp4`, ...) of the backing
  /// [AssetDbModel], when this page is showing a database asset rather than an
  /// arbitrary file/network image. Its presence is what enables the info
  /// button -- the asset itself is only fetched when that button is tapped.
  final String? assetRelativePath;

  SpMediaViewerItem({
    required this.type,
    required this.tag,
    this.provider,
    required this.alt,
    this.scale = 1,
    this.builder,
    this.assetRelativePath,
  });

  bool get isVideo => type == AssetType.video;
}

/// Full-screen swipeable viewer for a mixed list of image/video assets.
///
/// Each page owns a complete, independent [Scaffold] -- its own app bar,
/// zoomable body, and bottom bar -- rather than sharing state with siblings.
/// Tapping the center of a page toggles its own app bar + bottom bar
/// together; nothing about a video page's controls or an image page's alt
/// text leaks into another page's state. Image and video pages live in
/// separate part files ([_ImagePageScaffold], [_VideoPageScaffold]).
class SpMediaViewer extends StatefulWidget {
  const SpMediaViewer({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<SpMediaViewerItem> items;
  final int initialIndex;

  factory SpMediaViewer.fromString({
    required List<String> images,
    required int initialIndex,
    required BuildContext context,
  }) {
    final List<SpMediaViewerItem> items = [];

    for (final path in images) {
      // Non-null only for relative asset paths (images/, audio/, videos/),
      // which are the ones backed by an AssetDbModel row.
      final String? assetRelativePath = AssetType.getTypeFromLink(path) != null ? path : null;

      if (AssetType.getTypeFromLink(path) == AssetType.video) {
        items.add(
          SpMediaViewerItem(type: AssetType.video, tag: path, alt: null, assetRelativePath: assetRelativePath),
        );
        continue;
      }

      ImageProvider? imageProvider;

      // Check if this is a relative asset path (images/ or audio/)
      if (path.startsWith('images/') || path.startsWith('audio/')) {
        imageProvider = SpDbImageProvider(
          relativePath: path,
          currentUser: context.read<BackupProvider>().currentGoogleUser,
        );
      } else if (path.startsWith('http')) {
        imageProvider = CachedNetworkImageProvider(path);
      } else if (File(path).existsSync()) {
        imageProvider = FileImage(File(path));
      }

      if (imageProvider == null) continue;
      items.add(
        SpMediaViewerItem(
          type: AssetType.image,
          tag: path,
          provider: imageProvider,
          alt: null,
          assetRelativePath: assetRelativePath,
        ),
      );
    }

    return SpMediaViewer(
      initialIndex: items.length != images.length ? 0 : initialIndex,
      items: items,
    );
  }

  Future<void> show(BuildContext context) async {
    if (items.isEmpty) return;

    AnalyticsService.instance.logViewImages(
      imagesCount: items.length,
    );

    await context.pushTransparentRoute(
      this,
      rootNavigator: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<SpMediaViewer> createState() => _SpMediaViewerState();
}

class _SpMediaViewerState extends State<SpMediaViewer> {
  late final PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController(
      initialPage: min(widget.initialIndex, widget.items.length - 1),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      backgroundColor: Colors.black12,
      onDismissed: () => Navigator.of(context).pop(),
      direction: DismissiblePageDismissDirection.vertical,
      isFullScreen: true,
      child: PageView.builder(
        controller: controller,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          index = index % widget.items.length;
          final item = widget.items[index];

          if (item.isVideo) {
            return _VideoPageScaffold(item: item, index: index, total: widget.items.length, controller: controller);
          }

          return _ImagePageScaffold(item: item, index: index, total: widget.items.length);
        },
      ),
    );
  }
}

/// Shared chrome (title, info, share, close) every page's app bar renders the
/// same way -- kept as a plain function rather than a widget since it's
/// stateless given (index, total, item).
AppBar _buildAppBar(BuildContext context, {required int index, required int total, required SpMediaViewerItem item}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    foregroundColor: _foregroundColor,
    elevation: 0.0,
    automaticallyImplyLeading: false,
    title: Text(
      '${index + 1}/$total',
      style: TextTheme.of(context).titleMedium?.copyWith(color: _foregroundColor),
    ),
    actions: [
      _ShareButton(tag: item.tag),
      if (item.assetRelativePath != null) _InfoButton(assetRelativePath: item.assetRelativePath!),
      const CloseButton(color: _foregroundColor),
    ],
  );
}

/// Fades the app bar / bottom bar together whenever a page's center is
/// tapped, without affecting the body's layout (both slots stay mounted at
/// their normal size via [Scaffold.extendBody] / [Scaffold.extendBodyBehindAppBar]).
class _Chrome extends StatelessWidget {
  const _Chrome({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: Durations.medium1,
        curve: Curves.ease,
        child: child,
      ),
    );
  }
}

/// Opens [SpAssetInfoSheet] for the page's database asset. The asset row is
/// only looked up on tap -- pages are cheap to build and most of them are
/// never asked for their info.
class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.assetRelativePath});

  final String assetRelativePath;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: _foregroundColor,
      icon: const Icon(SpIcons.info),
      onPressed: () async {
        final asset = await AssetDbModel.findBy(relativePath: assetRelativePath);
        if (!context.mounted || asset == null) return;
        SpAssetInfoSheet(asset: asset).show(context: context);
      },
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    String? existFilePath;

    int? id = AssetType.parseAssetId(tag);
    AssetType? type = AssetType.getTypeFromLink(tag);

    if (id != null && type != null) {
      String filePath = type.getStoragePath(id: id, extension: extension(tag));
      if (File(filePath).existsSync()) existFilePath = filePath;
    }

    return Visibility(
      visible: existFilePath != null,
      child: Builder(
        builder: (context) {
          return IconButton(
            color: _foregroundColor,
            icon: const Icon(SpIcons.share),
            onPressed: () {
              if (existFilePath == null) return;

              RenderBox? box = context.findRenderObject() as RenderBox?;
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(existFilePath)],
                  sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
