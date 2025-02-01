part of 'story_tile.dart';

class _StoryTileTags extends StatelessWidget {
  const _StoryTileTags({
    required this.story,
  });

  final StoryDbModel story;

  @override
  Widget build(BuildContext context) {
    return Consumer<TagsProvider>(builder: (context, provider, child) {
      final tags = provider.tags?.items.where((e) => story.validTags?.contains(e.id) == true).toList() ?? [];

      final children = tags.map((tag) {
        return buildTag(context, provider, tag);
      }).toList();

      if (story.showDayCount) {
        final different = DateTime.now().difference(story.displayPathDate);
        children.add(
          buildPin(
            context: context,
            title: "📌 ${different.inDays} days",
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                useRootNavigator: true,
                builder: (context) {
                  return Container(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Looking Back',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          "It's been ${different.inDays} days",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(color: ColorScheme.of(context).primary),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      }

      return Wrap(
        spacing: MediaQuery.textScalerOf(context).scale(4),
        runSpacing: MediaQuery.textScalerOf(context).scale(4),
        children: children,
      );
    });
  }

  Widget buildTag(BuildContext context, TagsProvider provider, TagDbModel tag) {
    return buildPin(
      context: context,
      title: "# ${tag.title}",
      onTap: () => provider.viewTag(context: context, tag: tag, storyViewOnly: false),
    );
  }

  Material buildPin({
    required BuildContext context,
    required String title,
    required void Function()? onTap,
  }) {
    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      color: ColorScheme.of(context).readOnly.surface2,
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.textScalerOf(context).scale(7),
            vertical: MediaQuery.textScalerOf(context).scale(1),
          ),
          child: Text(
            title,
            style: TextTheme.of(context).labelMedium,
          ),
        ),
      ),
    );
  }
}
