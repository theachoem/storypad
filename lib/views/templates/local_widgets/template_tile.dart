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
        ?.map((e) => e.title?.trim().isNotEmpty == true ? e.title!.trim() : null)
        .whereType<String>()
        .join(" · ");

    final hasName = template.name?.trim().isNotEmpty == true;
    final hasBody = body?.trim().isNotEmpty == true;
    final hasTags = template.tags?.isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        onTap: onTap,
        title: Text(
          hasName ? template.name!.trim() : (hasBody ? body! : tr('general.na')),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: (hasName && hasBody) || hasTags
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasName && hasBody)
                    Text(
                      body!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (hasTags) ...[
                    const SizedBox(height: 8.0),
                    TemplateTagLabels(template: template),
                  ],
                ],
              )
            : null,
        trailing:
            [
              TargetPlatform.linux,
              TargetPlatform.windows,
              TargetPlatform.macOS,
            ].contains(Theme.of(context).platform)
            ? null
            : const Icon(SpIcons.dragIndicator),
      ),
    );
  }
}
