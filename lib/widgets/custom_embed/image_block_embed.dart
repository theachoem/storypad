import 'dart:io';
import 'dart:convert';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/core/extensions/color_scheme_extensions.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/custom_embed/unsupported.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class ImageBlockEmbed extends quill.EmbedBuilder {
  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return _QuillImageRenderer(
      controller: embedContext.controller,
      readOnly: embedContext.readOnly,
      node: embedContext.node,
    );
  }
}

class _QuillImageRenderer extends StatelessWidget {
  const _QuillImageRenderer({
    required this.node,
    required this.controller,
    required this.readOnly,
  });

  final quill.Embed node;
  final quill.QuillController controller;
  final bool readOnly;

  String standardizeImageUrl(String url) {
    if (url.contains('base64')) {
      return url.split(',')[1];
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = standardizeImageUrl(node.value.data);

    return Wrap(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: () => viewImage(context, imageUrl),
          onTap: () => readOnly ? onTap(context, imageUrl) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Hero(
              tag: imageUrl,
              child: buildImageByUrl(
                imageUrl,
                width: double.infinity,
                context: context,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildImageByUrl(
    String imageUrl, {
    required double? width,
    required BuildContext context,
  }) {
    bool isImageBase64(String imageUrl) {
      if (imageUrl.startsWith('http')) return false;
      return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageUrl);
    }

    if (isImageBase64(imageUrl)) {
      return Image.memory(
        base64.decode(imageUrl),
        width: width,
        height: null,
      );
    } else if (imageUrl.startsWith('http')) {
      return buildNetworkImage(imageUrl, width);
    } else if (File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        width: width,
        height: null,
      );
    } else {
      return SpTapEffect(
        onTap: () {},
        child: const QuillUnsupportedRenderer(message: "Invalid Images Sources"),
      );
    }
  }

  Widget buildNetworkImage(String imageUrl, double? width) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: null,
      fit: BoxFit.fitWidth,
      placeholder: (context, url) {
        return Container(
          width: width,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: ColorScheme.of(context).readOnly.surface3,
          ),
          child: const CircularProgressIndicator.adaptive(),
        );
      },
      errorWidget: (context, url, error) {
        bool driveImage = url.startsWith('https://drive.google.com/uc?export=download&id=');

        return QuillUnsupportedRenderer(
          message: driveImage ? "404" : "$error\n:$imageUrl",
          buttonLabel: "Show URL",
          onPressed: () async {
            final result = await showOkCancelAlertDialog(
              context: context,
              title: "Image Sources",
              message: url,
              okLabel: "Copy Link",
            );

            if (result == OkCancelResult.ok) {
              Clipboard.setData(ClipboardData(text: url));
            }
          },
        );
      },
    );
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
        if (context.mounted) UrlOpenerService().open(context, imageUrl);
        break;
      case "view":
        if (context.mounted) viewImage(context, imageUrl);
        break;
      default:
    }
  }

  Future<void> viewImage(BuildContext context, String imageUrl) async {
    SpImagesViewer.fromString(
      images: [imageUrl],
      initialIndex: 0,
    ).show(context);
  }
}
