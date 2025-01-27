part of 'story_tile.dart';

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
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Hero(
            tag: images[index],
            child: Material(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: buildImage(images[index]),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: displayMoreButton ? ColorScheme.of(context).surface.withValues(alpha: 0.8) : Colors.transparent,
            borderOnForeground: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onLongPress: () {
                SpImagesViewer.fromString(
                  images: images,
                  initialIndex: index,
                ).show(context);
              },
              onTap: () {
                SpImagesViewer.fromString(
                  images: images,
                  initialIndex: index,
                ).show(context);
              },
              child: displayMoreButton ? Center(child: Text("1+")) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildImage(String imageUrl) {
    if (QuillService.isImageBase64(imageUrl)) {
      return Image.memory(
        base64.decode(imageUrl),
        height: 56,
        width: 56,
        fit: BoxFit.cover,
      );
    } else if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 56,
        width: 56,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, progress) => SpGradientLoading(width: 56, height: 56),
      );
    } else if (File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        height: 56,
        width: 56,
        fit: BoxFit.cover,
      );
    } else {
      return Container();
    }
  }
}
