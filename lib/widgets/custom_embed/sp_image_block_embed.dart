import 'dart:math';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/sp_image.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';

class SpImageBlockEmbed extends quill.EmbedBuilder {
  final List<String> Function() fetchAllImages;

  SpImageBlockEmbed({
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

// TODO: add translation here.
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

  @override
  Widget build(BuildContext context) {
    String link = node.value.data;

    return LayoutBuilder(builder: (context, constraints) {
      double width = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));
      double height = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onDoubleTap: () => viewImage(context, link),
            onTap: () => onTap(context, link),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SpImage(
                link: link,
                width: width,
                height: height,
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> onTap(BuildContext context, String link) async {
    List<SheetAction<String>> actions = [
      if (link.startsWith('http')) ...[
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

    if (!context.mounted) return;
    if (actions.length == 1 && actions.first.key == 'view') {
      viewImage(context, link);
      return;
    }

    String? result = await showModalActionSheet<String>(
      context: context,
      title: "Images",
      actions: actions,
    );

    switch (result) {
      case "copy-link":
        await Clipboard.setData(ClipboardData(text: link));
        if (context.mounted) MessengerService.of(context).showSnackBar("Copied", showAction: false);
        break;
      case "view-on-web":
        if (context.mounted) UrlOpenerService.openInCustomTab(context, link);
        break;
      case "view":
        if (context.mounted) viewImage(context, link);
        break;
      default:
    }
  }

  Future<void> viewImage(BuildContext context, String link) async {
    List<String> images = fetchAllImages();

    if (images.contains(link)) {
      SpImagesViewer.fromString(
        images: images,
        initialIndex: images.indexOf(link),
      ).show(context);
    } else {
      SpImagesViewer.fromString(
        images: [link],
        initialIndex: 0,
      ).show(context);
    }
  }
}
