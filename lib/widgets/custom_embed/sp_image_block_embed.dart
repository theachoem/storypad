import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/widgets/sp_image.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

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
        children: [
          SpTapEffect(
            effects: [SpTapEffectType.scaleDown],
            onTap: readOnly ? () => viewImage(context, link) : null,
            child: Material(
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
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
