part of '../show/show_add_on_view.dart';

class _DemoImages extends StatelessWidget {
  const _DemoImages({
    required this.demoImageUrls,
    required this.context,
  });

  final List<String>? demoImageUrls;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    if (demoImageUrls == null) return buildSkelaton(context);

    return SizedBox(
      height: 240,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: demoImageUrls?.length ?? 0,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12.0),
        itemBuilder: (context, index) {
          final imageUrl = demoImageUrls![index];

          return SpFadeIn(
            child: GestureDetector(
              onTap: () => SpImagesViewer.fromString(
                initialIndex: index,
                images: demoImageUrls!,
              ).show(context),
              child: Material(
                clipBehavior: Clip.hardEdge,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSkelaton(BuildContext context) {
    return Container(
      height: 240,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        spacing: 12.0,
        children: [
          Container(
            width: 110,
            decoration: BoxDecoration(
              color: ColorScheme.of(context).readOnly.surface1,
              borderRadius: BorderRadiusGeometry.circular(8.0),
            ),
          ),
          Container(
            width: 110,
            decoration: BoxDecoration(
              color: ColorScheme.of(context).readOnly.surface1,
              borderRadius: BorderRadiusGeometry.circular(8.0),
            ),
          ),
        ],
      ),
    );
  }
}
