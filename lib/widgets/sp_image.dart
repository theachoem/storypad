import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/asset_db/sp_db_image_provider.dart';
import 'package:storypad/widgets/sp_gradient_loading.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpImage extends StatelessWidget {
  const SpImage({
    super.key,
    required this.link,
    required this.width,
    required this.height,
    this.errorWidget,
  });

  final String link;
  final double? width;
  final double? height;
  final LoadingErrorWidgetBuilder? errorWidget;

  double get defaultSize => 50;

  static bool isImageBase64(String content) {
    if (content.startsWith('http')) return false;
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(content);
  }

  @override
  Widget build(BuildContext context) {
    if (link.startsWith("storypad://")) {
      return Consumer<BackupProvider>(
        builder: (context, provider, child) {
          return Image(
            key: ValueKey(provider.currentUser?.accessToken),
            width: width,
            height: height,
            fit: BoxFit.cover,
            image: SpDbImageProvider(embedLink: link, currentUser: provider.currentUser),
            errorBuilder: (context, error, strackTrace) =>
                errorWidget?.call(context, link, error) ??
                buildImageError(width ?? defaultSize, height ?? defaultSize, context, error),
            loadingBuilder: (context, child, loadingProgress) {
              return Stack(
                children: [
                  SpGradientLoading(
                    height: height ?? defaultSize,
                    width: width ?? defaultSize,
                  ),
                  child,
                ],
              );
            },
          );
        },
      );
    } else if (isImageBase64(link)) {
      return Image.memory(
        base64.decode(link),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (link.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: link,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          return SpGradientLoading(
            height: height ?? defaultSize,
            width: width ?? defaultSize,
          );
        },
        errorWidget: errorWidget,
      );
    } else if (File(link).existsSync()) {
      return Image.file(
        File(link),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      return buildImageError(
        width ?? defaultSize,
        height ?? defaultSize,
        context,
        null,
      );
    }
  }

  static Widget buildImageError(double width, double height, BuildContext context, Object? error) {
    String? message = error is StateError ? error.message : error?.toString();
    return Material(
      color: ColorScheme.of(context).readOnly.surface3,
      child: Container(
        width: width,
        height: height,
        constraints: const BoxConstraints(minHeight: 112),
        child: Wrap(
          spacing: 8.0,
          runAlignment: WrapAlignment.center,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8.0,
          children: [
            const Icon(SpIcons.imageNotSupported),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
