part of '../sp_story_tile.dart';

class _StoryTileAssets extends StatelessWidget {
  const _StoryTileAssets({
    required this.assetLinks,
  });

  // eg. ['storypad://assets/1762500783746', 'storypad://assets/1762500985286']
  final List<String> assetLinks;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: min(4, assetLinks.length),
          separatorBuilder: (context, index) => const SizedBox(width: 8.0),
          itemBuilder: (context, index) {
            return _AssetTile(
              assetLink: assetLinks[index],
              displayMoreButton: index == 3 && assetLinks.length > 4,
              allAssetLinks: assetLinks,
            );
          },
        ),
      ),
    );
  }
}

/// Displays a single asset tile from a link (image or audio)
class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.assetLink,
    required this.displayMoreButton,
    required this.allAssetLinks,
  });

  final String assetLink;
  final bool displayMoreButton;
  final List<String> allAssetLinks;

  // Detect if link is audio or image
  bool get _isAudio => AssetType.getTypeFromLink(assetLink) == AssetType.audio;

  @override
  Widget build(BuildContext context) {
    if (_isAudio) return _buildAudioTile(context);
    return _buildImageTile(context);
  }

  Widget _buildImageTile(BuildContext context) {
    return Stack(
      children: [
        Material(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: SpImage(
            link: assetLink,
            height: 56,
            width: 56,
            errorWidget: (context, url, error) {
              return Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                ),
                child: Icon(
                  SpIcons.imageNotSupported,
                  color: Theme.of(context).colorScheme.error,
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Material(
            color: displayMoreButton
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                : Colors.transparent,
            borderOnForeground: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onLongPress: () => _viewImages(context),
              onTap: () => _viewImages(context),
              child: displayMoreButton
                  ? Center(
                      child: Text(
                        '+${allAssetLinks.length - 4}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioTile(BuildContext context) {
    return Material(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Icon(
            SpIcons.voice,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _viewImages(BuildContext context) {
    // Filter to only image links for the viewer
    final imageLinks = allAssetLinks.where((link) => AssetType.getTypeFromLink(link) != AssetType.audio).toList();
    SpImagesViewer.fromString(
      images: imageLinks,
      initialIndex: 0,
    ).show(context);
  }
}
