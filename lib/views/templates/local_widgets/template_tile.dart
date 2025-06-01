part of '../templates_view.dart';

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.viewModel,
    required this.template,
  });

  final TemplatesViewModel viewModel;
  final TemplateDbModel template;

  @override
  Widget build(BuildContext context) {
    List<String> promps = [];
    final pages = template.content?.richPages ?? <StoryPageDbModel>[];

    for (int i = 1; i < pages.length; i++) {
      promps.add(pages[i].title ?? tr('general.na'));
    }

    return ListTile(
      onTap: () => viewModel.goToEditPage(context, template),
      title: Text(template.content?.richPages?.firstOrNull?.title ?? tr('general.na')),
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0).copyWith(right: 4.0),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(SpIcons.moreVert),
          ),
        ],
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (template.content?.displayShortBody?.trim().isNotEmpty == true)
            SpMarkdownBody(body: template.content!.displayShortBody!),
          if (promps.isNotEmpty)
            Text(
              promps.join("\n"),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8.0),
          Consumer<TagsProvider>(builder: (context, provider, _) {
            List<TagDbModel> tags = [];

            for (TagDbModel tag in provider.tags?.items ?? []) {
              if (template.tags?.contains(tag.id) == true) {
                tags.add(tag);
              }
            }

            return Wrap(
              spacing: MediaQuery.textScalerOf(context).scale(4),
              runSpacing: MediaQuery.textScalerOf(context).scale(4),
              children: tags.map((tag) {
                return Material(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  color: (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    onTap: () => ShowTagRoute(tag: tag, storyViewOnly: true).push(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.textScalerOf(context).scale(7),
                        vertical: MediaQuery.textScalerOf(context).scale(1),
                      ),
                      child: Text(
                        tag.title,
                        style: TextTheme.of(context).labelMedium,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          })
        ],
      ),
    );
  }
}
