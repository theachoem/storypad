import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/quill_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/custom_embed/unsupported.dart';
import 'package:storypad/widgets/sp_gradient_loading.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';

class ImageBlockEmbed extends quill.EmbedBuilder {
  final List<String> Function() fetchAllImages;

  ImageBlockEmbed({
    required this.fetchAllImages,
  });

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return _QuillImageRenderer(
      controller: embedContext.controller,
      readOnly: embedContext.readOnly,
      node: embedContext.node,
      fetchAllImages: fetchAllImages,
    );
  }
}

class _QuillImageRenderer extends StatelessWidget {
  const _QuillImageRenderer({
    required this.node,
    required this.controller,
    required this.readOnly,
    required this.fetchAllImages,
  });

  final quill.Embed node;
  final quill.QuillController controller;
  final bool readOnly;
  final List<String> Function() fetchAllImages;

  String standardizeImageUrl(String url) {
    if (url.contains('base64')) {
      return url.split(',')[1];
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = standardizeImageUrl(node.value.data);

    return LayoutBuilder(builder: (context, constraints) {
      double width = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));
      double height = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.textScalerOf(context).scale(node.documentOffset == 0 ? 4 : 12),
              bottom: MediaQuery.textScalerOf(context).scale(12),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => viewImage(context, imageUrl),
              onTap: () => readOnly ? onTap(context, imageUrl) : null,
              child: Hero(
                tag: imageUrl,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: buildImageByUrl(
                    imageUrl,
                    context: context,
                    width: width,
                    height: height,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget buildImageByUrl(
    String imageUrl, {
    required double width,
    required double height,
    required BuildContext context,
  }) {
    if (QuillService.isImageBase64(imageUrl)) {
      return Image.memory(
        base64.decode(imageUrl),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (imageUrl.startsWith('http')) {
      return buildNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
      );
    } else if (File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: ColorScheme.of(context).tertiaryContainer),
        child: const Icon(Icons.error),
      );
    }
  }

  Widget buildNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        return SpGradientLoading(
          height: height,
          width: width,
        );
      },
      errorWidget: (context, url, error) {
        bool driveImage = url.startsWith('https://drive.google.com/uc?export=download&id=');

        return QuillUnsupportedRenderer(
          message: driveImage ? "404" : "$error\n:$imageUrl",
          buttonLabel: "Show URL",
          onPressed: () => showSourceCopyAlert(context, url),
        );
      },
    );
  }

  Future<void> showSourceCopyAlert(BuildContext context, String url) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: "Image Sources",
      message: url,
      okLabel: "Copy Link",
    );

    if (result == OkCancelResult.ok) {
      Clipboard.setData(ClipboardData(text: url));
    }
  }

  Future<void> onTap(BuildContext context, String imageUrl) async {
    List<SheetAction<String>> actions = [
      if (imageUrl.startsWith('http')) ...[
        const SheetAction(
          label: "View on web",
          key: "view-on-web",
          icon: Icons.web,
        ),
        const SheetAction(
          label: "Copy link",
          key: "copy-link",
          icon: Icons.link,
        ),
      ],
      const SheetAction(
        label: "View",
        key: "view",
        icon: Icons.image,
      ),
    ];

    if (actions.length == 1 && actions.first.key == 'view') {
      viewImage(context, imageUrl);
      return;
    }

    String? result = await showModalActionSheet<String>(
      context: context,
      title: "Images",
      actions: actions,
    );

    switch (result) {
      case "copy-link":
        await Clipboard.setData(ClipboardData(text: imageUrl));
        if (context.mounted) MessengerService.of(context).showSnackBar("Copied", showAction: false);
        break;
      case "view-on-web":
        if (context.mounted) UrlOpenerService.openInCustomTab(context, imageUrl);
        break;
      case "view":
        if (context.mounted) viewImage(context, imageUrl);
        break;
      default:
    }
  }

  Future<void> viewImage(BuildContext context, String imageUrl) async {
    final images = fetchAllImages();

    if (images.contains(imageUrl)) {
      SpImagesViewer.fromString(
        images: images,
        initialIndex: images.indexOf(imageUrl),
      ).show(context);
    } else {
      SpImagesViewer.fromString(
        images: [imageUrl],
        initialIndex: 0,
      ).show(context);
    }
  }
}
