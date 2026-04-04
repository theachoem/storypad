part of '../paywall_features_view.dart';

class _DemoImages extends StatelessWidget {
  const _DemoImages({
    required this.demoImageUrls,
    required this.context,
    required this.skeletonCount,
  });

  final List<String>? demoImageUrls;
  final int skeletonCount;
  final BuildContext context;

  double get height => 320.0;

  @override
  Widget build(BuildContext context) {
    if (demoImageUrls == null) return buildSkelaton(context);

    return Container(
      height: height,
      alignment: .center,
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisSize: .min,
          spacing: 12.0,
          children: List.generate(demoImageUrls?.length ?? 0, (index) {
            return buildDemo(index, context);
          }),
        ),
      ),
    );
  }

  Widget buildDemo(int index, BuildContext context) {
    final imageUrl = demoImageUrls![index];
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
          ),
        ),
      ),
    );
  }

  Widget buildSkelaton(BuildContext context) {
    return Container(
      alignment: .center,
      height: height,
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          spacing: 12.0,
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          children: List.generate(skeletonCount, (index) {
            return Container(
              width: height * 0.45,
              decoration: BoxDecoration(
                color: ColorScheme.of(context).readOnly.surface1,
                borderRadius: BorderRadiusGeometry.circular(8.0),
              ),
            );
          }),
        ),
      ),
    );
  }
}
