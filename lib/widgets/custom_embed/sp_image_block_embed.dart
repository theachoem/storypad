import 'dart:async';
import 'dart:math';
import 'package:animated_clipper/animated_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/app_theme.dart';
import 'package:storypad/widgets/quill/custom_attributes/embed_alignment_attribute.dart';
import 'package:storypad/widgets/quill/custom_attributes/embed_size_attribute.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        double? width;
        double? height;

        if (EmbedSizeAttribute.maxSize.hasApplied(node)) {
          width = double.infinity;
          height = null;
        } else {
          width = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));
          height = min(constraints.maxWidth, MediaQuery.textScalerOf(context).scale(150));
        }

        return Container(
          width: double.infinity,
          alignment:
              EmbedAlignmentAttribute.toAlignment(node) ??
              AppTheme.getDirectionValue(context, Alignment.centerRight, Alignment.centerLeft),
          child: Stack(
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
              if (!readOnly)
                Positioned(
                  top: 0,
                  right: 0,
                  child: buildMoreVertButton(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildMoreVertButton(BuildContext context) {
    List<IconButton> buttons = [
      IconButton(
        isSelected: EmbedAlignmentAttribute.left.hasApplied(node),
        icon: const Icon(Icons.format_align_left),
        onPressed: EmbedSizeAttribute.maxSize.hasApplied(node)
            ? null
            : () => EmbedAlignmentAttribute.left.toggle(controller, node),
      ),
      IconButton(
        isSelected: EmbedAlignmentAttribute.center.hasApplied(node),
        icon: const Icon(Icons.format_align_center),
        onPressed: EmbedSizeAttribute.maxSize.hasApplied(node)
            ? null
            : () => EmbedAlignmentAttribute.center.toggle(controller, node),
      ),
      IconButton(
        isSelected: EmbedAlignmentAttribute.right.hasApplied(node),
        icon: const Icon(Icons.format_align_right),
        onPressed: EmbedSizeAttribute.maxSize.hasApplied(node)
            ? null
            : () => EmbedAlignmentAttribute.right.toggle(controller, node),
      ),
      IconButton(
        icon: const Icon(SpIcons.zoomInMap),
        onPressed: () => EmbedSizeAttribute.toggle(controller, node),
      ),
      IconButton(
        color: ColorScheme.of(context).error,
        icon: const Icon(SpIcons.delete),
        onPressed: () => controller.replaceText(node.documentOffset, node.length, '', controller.selection),
      ),
    ];

    int rowCount = (buttons.length / 4).ceilToDouble().toInt();

    double itemSize = 48;
    double padding = 4.0;

    double contentsWidth = itemSize * min(3, buttons.length);
    double width = contentsWidth + padding * 2 + 2;
    double height = itemSize * rowCount + padding * 2 + 2;

    return SpFloatingPopUpButton(
      estimatedFloatingWidth: width,
      bottomToTop: false,
      dyGetter: (dy) => dy + 48,
      pathBuilder: PathBuilders.slideDown,
      floatingBuilder: (FutureOr<void> Function() close) {
        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Wrap(
            spacing: 0.0,
            runSpacing: 0.0,
            children: buttons.map((button) {
              bool selected = button.onPressed != null && button.isSelected == true;

              return SizedBox(
                width: itemSize,
                height: itemSize,
                child: Center(
                  child: IconButton(
                    isSelected: selected,
                    icon: button.icon,
                    color: button.color,
                    style: IconButton.styleFrom(
                      side: selected ? BorderSide(color: Theme.of(context).dividerColor) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: button.onPressed == null
                        ? null
                        : () async {
                            await close();
                            button.onPressed!();
                          },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      builder: (callback) {
        return IconButton.filledTonal(
          icon: const Icon(SpIcons.moreVert),
          onPressed: callback,
        );
      },
    );
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
