import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';

class SpDemoImages extends StatelessWidget {
  const SpDemoImages({
    super.key,
    this.demoImageUrls,
    this.demoImageUrlPaths,
    required this.skeletonCount,
  }) : assert(demoImageUrls != null || demoImageUrlPaths != null);

  final List<String>? demoImageUrls;
  final List<String>? demoImageUrlPaths;

  final int skeletonCount;

  double get height => 320.0;
  double get width {
    final imageIds = [
      ...?demoImageUrls,
      ...?demoImageUrlPaths,
    ];

    if (imageIds.any((imageId) => imageId.contains('backgrounds'))) {
      return height * 1;
    }

    return height * 9 / 20;
  }

  int get itemCount => demoImageUrls?.length ?? demoImageUrlPaths?.length ?? skeletonCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: .center,
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        clipBehavior: .none,
        child: Row(
          mainAxisSize: .min,
          spacing: 12.0,
          children: List.generate(itemCount, (index) {
            return buildDemo(index, context);
          }),
        ),
      ),
    );
  }

  Widget buildDemo(int index, BuildContext context) {
    final imageUrl = demoImageUrls?.elementAtOrNull(index);
    if (imageUrl != null) {
      return buildRemoteImage(
        context: context,
        index: index,
        imageUrl: imageUrl,
      );
    }

    final urlPath = demoImageUrlPaths?.elementAtOrNull(index);
    if (urlPath == null) return buildLoading(context);

    return SpFirestoreStorageDownloaderBuilder(
      filePath: urlPath,
      builder: (context, file, failed) {
        if (file == null) return buildLoading(context);

        return buildLocalImage(
          context: context,
          index: index,
          filePath: file.path,
        );
      },
    );
  }

  Widget buildRemoteImage({
    required BuildContext context,
    required int index,
    required String imageUrl,
  }) {
    final urls = demoImageUrls;
    if (urls == null) return buildLoading(context);

    return SpFadeIn(
      child: SizedBox(
        width: width,
        child: GestureDetector(
          onTap: () => SpImagesViewer.fromString(
            initialIndex: index,
            images: urls,
            context: context,
          ).show(context),
          child: Material(
            clipBehavior: Clip.hardEdge,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              filterQuality: FilterQuality.high,
              width: width,
              height: height,
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) => buildLoading(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLocalImage({
    required BuildContext context,
    required int index,
    required String filePath,
  }) {
    return SpFadeIn(
      child: SizedBox(
        width: width,
        child: GestureDetector(
          onTap: () async => openLocalViewer(context, index),
          child: Material(
            clipBehavior: Clip.hardEdge,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
            child: Image.file(
              File(filePath),
              filterQuality: FilterQuality.high,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => buildLoading(context),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openLocalViewer(BuildContext context, int initialIndex) async {
    final urlPaths = demoImageUrlPaths;
    if (urlPaths == null || urlPaths.isEmpty) return;

    final localFilePaths = await Future.wait(
      urlPaths.map((urlPath) => CloudStorageService.instance.downloadFile(urlPath).then((e) => e.file?.path)),
    ).then((paths) => paths.whereType<String>().toList());

    if (localFilePaths.isEmpty || !context.mounted) return;

    await SpImagesViewer.fromString(
      initialIndex: demoImageUrlPaths?.length == localFilePaths.length ? initialIndex : 0,
      images: localFilePaths,
      context: context,
    ).show(context);
  }

  Container buildLoading(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ColorScheme.of(context).readOnly.surface1,
        borderRadius: BorderRadiusGeometry.circular(8.0),
      ),
    );
  }
}
