part of 'templates_tab.dart';

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.onTap,
    required this.template,
  });

  final void Function() onTap;
  final TemplateDbModel template;

  @override
  Widget build(BuildContext context) {
    String? body = template.content?.richPages
        ?.map((e) => e.title?.trim().isNotEmpty == true ? "- ${e.title}" : null)
        .whereType<String>()
        .join("\n");

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8.0)),
        title: Text(template.name ?? tr('general.na')),
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        isThreeLine: true,
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8.0),
              SpMarkdownBody(body: body!),
              const SizedBox(height: 8.0),
            ],
            TemplateTagLabels(template: template),
          ],
        ),
      ),
    );
  }
}
