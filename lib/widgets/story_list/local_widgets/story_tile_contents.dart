part of '../sp_story_tile.dart';

class _StoryTileContents extends StatelessWidget {
  const _StoryTileContents({
    required this.story,
    required this.viewOnly,
    required this.listContext,
    required this.hasTitle,
    required this.content,
    required this.hasBody,
    required this.displayShortBody,
    required this.preferences,
  });

  final StoryDbModel story;
  final bool viewOnly;
  final BuildContext listContext;
  final bool hasTitle;
  final StoryContentDbModel? content;
  final bool hasBody;
  final String? displayShortBody;
  final StoryTilePreferencesObject preferences;

  void _viewAssetImageAt(BuildContext context, List<String> assetPaths, int index) {
    SpMediaViewer.fromString(
      images: assetPaths,
      initialIndex: index,
      context: context,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    // `media()` returns both photos and videos (they share one embed type by
    // design) -- rendering/tap-handling branches per path.
    final assetPaths = content != null ? StoryContentEmbedExtractor.media(content) : null;

    final audioPaths = (story.draftContent ?? story.latestContent) != null
        ? StoryContentEmbedExtractor.audio(story.draftContent ?? story.latestContent)
        : null;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preferences.showTime) ...[
            Consumer<DevicePreferencesProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.timeFormatOf(context).formatTime(story.displayPathDate, context.locale),
                  style: TextTheme.of(context).labelMedium,
                );
              },
            ),
            SizedBox(height: MediaQuery.textScalerOf(context).scale(4)),
          ],
          if (hasTitle)
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              width: double.infinity,
              child: Text(
                content!.title!.sanitizeUtf16,
                style: TextTheme.of(context).titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (hasBody)
            Container(
              width: double.infinity,
              margin: hasTitle
                  ? EdgeInsets.only(top: MediaQuery.textScalerOf(context).scale(6.0))
                  : AppTheme.getDirectionValue(
                      context,
                      const EdgeInsets.only(left: 24.0),
                      const EdgeInsets.only(right: 24.0),
                    ),
              child: SpMarkdownBody(body: displayShortBody!),
            ),
          SpStoryLabels(
            story: story,
            fromStoryTile: true,
            voicesCount: audioPaths?.length,
            margin: EdgeInsets.only(top: MediaQuery.textScalerOf(context).scale(8)),
            preferences: preferences,
            onToggleShowDayCount: viewOnly
                ? null
                : () async {
                    await StoryTileActions(story: story, storyListReloaderContext: listContext).toggleShowDayCount();
                    if (context.mounted) Navigator.maybePop(context);
                  },
            onChangeDate: viewOnly
                ? null
                : (newDateTime) async {
                    await StoryTileActions(story: story, storyListReloaderContext: listContext).changeDate(newDateTime);
                    if (context.mounted) Navigator.maybePop(context);
                  },
            onToggleManagingPage: null,
          ),
          if (assetPaths?.isNotEmpty == true) ...[
            SizedBox(height: MediaQuery.textScalerOf(context).scale(12)),
            if (preferences.photoCollage)
              // Full width on phones; capped on tablets/large screens so a single
              // square image doesn't become oversized.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: SpAlbumGrid(
                    paths: assetPaths!,
                    onTap: viewOnly ? null : (index) => _viewAssetImageAt(context, assetPaths, index),
                  ),
                ),
              )
            else
              _StoryTileAssets(assetPaths: assetPaths!),
          ],
        ],
      ),
    );
  }
}
