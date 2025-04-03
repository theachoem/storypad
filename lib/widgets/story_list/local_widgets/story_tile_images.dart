part of '../sp_story_tile.dart';

class _StoryTileImages extends StatelessWidget {
  const _StoryTileImages({
    required this.images,
  });

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: min(4, images.length),
          separatorBuilder: (context, index) => SizedBox(width: 8.0),
          itemBuilder: (context, index) {
            return buildImageBlock(
              context: context,
              index: index,
              displayMoreButton: index == 3 && images.length > 4,
            );
          },
        ),
      ),
    );
  }

  Stack buildImageBlock({
    required int index,
    required BuildContext context,
    bool displayMoreButton = false,
  }) {
    return Stack(
      children: [
        Material(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: SpImage(
            link: images[index],
            height: 56,
            width: 56,
            errorWidget: (context, url, error) {
              return Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(color: ColorScheme.of(context).readOnly.surface3),
                child: Icon(SpIcons.of(context).imageNotSupported),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Material(
            color: displayMoreButton ? ColorScheme.of(context).surface.withValues(alpha: 0.8) : Colors.transparent,
            borderOnForeground: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onLongPress: () => view(index, context),
              onTap: () => view(index, context),
              child: displayMoreButton ? Center(child: Text("1+")) : null,
            ),
          ),
        ),
      ],
    );
  }

  void view(int index, BuildContext context) async {
    if (!context.mounted) return;

    SpImagesViewer.fromString(
      images: images,
      initialIndex: index,
    ).show(context);
  }
}
