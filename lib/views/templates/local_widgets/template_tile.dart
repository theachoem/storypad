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

    return SpPopupMenuButton(
      dxGetter: (dx) => MediaQuery.of(context).size.width,
      dyGetter: (dy) => dy + 88,
      items: (BuildContext context) {
        return [
          SpPopMenuItem(
            leadingIconData: SpIcons.newStory,
            title: tr('button.use_template'),
            onPressed: () => viewModel.useTemplate(context, template),
            trailingIconData: SpIcons.keyboardRight,
          ),
          SpPopMenuItem(
            leadingIconData: SpIcons.book,
            title: tr('general.previous_stories'),
            onPressed: () => viewModel.goToShowPage(context, template),
          ),
          SpPopMenuItem(
            leadingIconData: SpIcons.edit,
            title: tr('button.edit'),
            onPressed: () => viewModel.goToEditPage(context, template),
          ),
          SpPopMenuItem(
            leadingIconData: SpIcons.deleteForever,
            titleStyle: TextStyle(color: ColorScheme.of(context).error),
            title: tr('button.delete'),
            onPressed: () => viewModel.delete(context, template),
          ),
        ];
      },
      builder: (callback) {
        return ListTile(
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
          onTap: callback,
          title: Text(template.content?.richPages?.firstOrNull?.title ?? tr('general.na')),
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          isThreeLine: true,
          trailing: const Icon(SpIcons.moreVert),
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
      },
    );
  }
}
