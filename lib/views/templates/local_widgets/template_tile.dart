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

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: ListTile(
        onTap: () => viewModel.goToShowPage(context, template),
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
        title: Text(template.content?.richPages?.firstOrNull?.title ?? tr('general.na')),
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        isThreeLine: true,
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
            TemplateTagLabels(template: template)
          ],
        ),
      ),
    );
  }
}
