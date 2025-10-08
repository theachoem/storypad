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
            const SizedBox(height: 8.0),
            TemplateTagLabels(template: template),
          ],
        ),
      ),
    );
  }
}
