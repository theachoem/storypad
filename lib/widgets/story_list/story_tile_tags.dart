part of 'story_tile.dart';

class _StoryTileTags extends StatelessWidget {
  const _StoryTileTags({
    required this.story,
  });

  final StoryDbModel story;

  @override
  Widget build(BuildContext context) {
    return Consumer<TagsProvider>(builder: (context, provider, child) {
      final tags = provider.tags?.items.where((e) => story.validTags?.contains(e.id) == true);

      return Wrap(
        spacing: MediaQuery.textScalerOf(context).scale(4),
        runSpacing: MediaQuery.textScalerOf(context).scale(4),
        children: tags!.map((tag) {
          return buildTag(context, provider, tag);
        }).toList(),
      );
    });
  }

  Widget buildTag(BuildContext context, TagsProvider provider, TagDbModel tag) {
    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      color: ColorScheme.of(context).readOnly.surface2,
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: () => provider.viewTag(context: context, tag: tag, storyViewOnly: false),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.textScalerOf(context).scale(7),
            vertical: MediaQuery.textScalerOf(context).scale(1),
          ),
          child: Text(
            "# ${tag.title}",
            style: TextTheme.of(context).labelMedium,
          ),
        ),
      ),
    );
  }
}
