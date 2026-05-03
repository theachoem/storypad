import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';

class SpDemoImages extends StatelessWidget {
  const SpDemoImages({
    super.key,
    required this.demoImageUrls,
    required this.context,
    required this.skeletonCount,
  });

  final List<String>? demoImageUrls;
  final int skeletonCount;
  final BuildContext context;

  double get height => 320.0;
  double get width {
    if (demoImageUrls != null && demoImageUrls!.any((url) => url.contains('backgrounds'))) {
      return height * 1;
    }

    return height * 9 / 20;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: .center,
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisSize: .min,
          spacing: 12.0,
          children: List.generate(demoImageUrls?.length ?? skeletonCount, (index) {
            return buildDemo(index, context);
          }),
        ),
      ),
    );
  }

  Widget buildDemo(int index, BuildContext context) {
    final imageUrl = demoImageUrls?.elementAtOrNull(index);
    if (imageUrl == null) return buildLoading(context);

    return SpFadeIn(
      child: GestureDetector(
        onTap: () => SpImagesViewer.fromString(
          initialIndex: index,
          images: demoImageUrls!,
          context: context,
        ).show(context),
        child: Material(
          clipBehavior: Clip.hardEdge,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            filterQuality: FilterQuality.high,
            height: height,
            progressIndicatorBuilder: (context, url, progress) => buildLoading(context),
          ),
        ),
      ),
    );
  }

  Container buildLoading(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: ColorScheme.of(context).readOnly.surface1,
        borderRadius: BorderRadiusGeometry.circular(8.0),
      ),
    );
  }
}
