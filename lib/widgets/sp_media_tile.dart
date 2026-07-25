import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/widgets/asset_db/sp_db_asset_loader.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_image.dart';

/// Renders [SpImage] for image paths, or a paused live video preview (first
/// frame + play-icon overlay) for video paths -- dispatches on
/// [AssetType.getTypeFromLink] so grid/album/embed call-sites don't need to
/// branch on asset type themselves.
class SpMediaTile extends StatelessWidget {
  const SpMediaTile({
    super.key,
    required this.link,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  final String link;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final LoadingErrorWidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (height != null) return _buildChild(width, height);

    // No fixed height (e.g. the quill "max size" single-embed layout) -- try
    // to resolve a persisted aspect ratio synchronously (no `Future`, no
    // reflow -- see `AssetsBox.findAspectRatioSync`), captured once at insert
    // time for both images and videos, so either kind of tile can size
    // correctly on its very first build, well before the file itself loads.
    final id = AssetType.parseAssetId(link);
    final persistedAspectRatio = id != null ? AssetDbModel.db.findAspectRatioSync(id) : null;

    if (persistedAspectRatio == null) {
      // No persisted ratio (link isn't a DB-tracked asset, or predates this
      // feature) -- fall back to each widget's own native sizing behavior
      // (Image's own decoded-size layout, or the video tile's live-controller
      // fallback), unchanged, permanently, for legacy assets. No backfill --
      // deliberately kept simple.
      return _buildChild(width, null);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = width != null && width!.isFinite ? width! : constraints.maxWidth;
        return _buildChild(effectiveWidth, effectiveWidth / persistedAspectRatio);
      },
    );
  }

  Widget _buildChild(double? width, double? height) {
    if (AssetType.getTypeFromLink(link) == AssetType.video) {
      return _SpVideoPreviewTile(
        link: link,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return SpImage(
      link: link,
      width: width,
      height: height,
      fit: fit,
      errorWidget: errorWidget,
    );
  }
}

class _SpVideoPreviewTile extends StatefulWidget {
  const _SpVideoPreviewTile({
    required this.link,
    required this.width,
    required this.height,
    required this.fit,
  });

  final String link;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  State<_SpVideoPreviewTile> createState() => _SpVideoPreviewTileState();
}

class _SpVideoPreviewTileState extends State<_SpVideoPreviewTile> {
  // Only reached when `SpMediaTile` found no persisted aspect ratio at all
  // (inserted before this existed, or extraction failed) and the live
  // controller hasn't initialized yet -- not the common path.
  static const double _fallbackAspectRatio = 1;

  VideoPlayerController? controller;
  bool initializing = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Video stays paused at its first decoded frame -- this is only ever a
  // preview tile, playback happens in the full-screen player.
  Future<void> _initController(File file) async {
    if (controller != null || initializing) return;
    initializing = true;

    final newController = VideoPlayerController.file(file);
    await newController.initialize();

    if (!mounted) {
      newController.dispose();
      return;
    }

    setState(() => controller = newController);
  }

  @override
  Widget build(BuildContext context) {
    return SpDbAssetLoader.withUser(
      relativePath: widget.link,
      builder: (context, file, error) {
        if (file != null) _initController(file);
        return _buildSizedTile(context);
      },
    );
  }

  // `SpMediaTile` already resolved a fixed height whenever it could (either
  // it was given one, or a persisted aspect ratio was found) -- height only
  // arrives null here when neither was available, so fall back to the live
  // controller's aspect ratio once it initializes, or a square guess before then.
  Widget _buildSizedTile(BuildContext context) {
    if (widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _buildStack(context),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.width != null && widget.width!.isFinite ? widget.width! : constraints.maxWidth;
        final aspectRatio = controller?.value.isInitialized == true
            ? controller!.value.aspectRatio
            : _fallbackAspectRatio;

        return SizedBox(
          width: width,
          height: width / aspectRatio,
          child: _buildStack(context),
        );
      },
    );
  }

  Widget _buildStack(BuildContext context) {
    return Stack(
      fit: .expand,
      children: [
        ClipRect(child: _buildPreview(context)),
        const Center(
          child: Icon(SpIcons.playCircle, color: Colors.white, size: 40.0),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final playerController = controller;
    if (playerController == null || !playerController.value.isInitialized) {
      return ColoredBox(color: ColorScheme.of(context).readOnly.surface3 ?? ColorScheme.of(context).surface);
    }

    return FittedBox(
      fit: widget.fit ?? BoxFit.cover,
      clipBehavior: .hardEdge,
      child: SizedBox(
        width: playerController.value.size.width,
        height: playerController.value.size.height,
        child: VideoPlayer(playerController),
      ),
    );
  }
}
