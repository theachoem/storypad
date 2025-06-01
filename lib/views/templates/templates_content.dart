part of 'templates_view.dart';

class _TemplatesContent extends StatelessWidget {
  const _TemplatesContent(this.viewModel);

  final TemplatesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("page.templates.title")),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(SpIcons.lightBulb),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  buildTemplateTile(context),
                  const Divider(height: 1),
                  buildTemplateTile(context),
                  ListTile(
                    title: const Text("Morning Routine"),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0).copyWith(right: 4.0),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(SpIcons.moreVert),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      [
                        "- What is my sleep?",
                        "- Todo",
                      ].join("\n"),
                      maxLines: 2,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(SpIcons.add),
              label: const Text("New Template"),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8.0)
          ],
        ),
      ),
    );
  }

  Widget buildTemplateTile(BuildContext context) {
    return ListTile(
      title: const Text("Workout Check In"),
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0).copyWith(right: 4.0),
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
        spacing: 8.0,
        children: [
          Text(
            [
              "- What is your day?",
              "- What is your day?",
              "- What is your day?",
            ].join("\n"),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Material(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
            color: (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.06),
            child: InkWell(
              borderRadius: BorderRadius.circular(4.0),
              onTap: () {},
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.textScalerOf(context).scale(7),
                  vertical: MediaQuery.textScalerOf(context).scale(1),
                ),
                child: Text(
                  'Workout 💪',
                  style: TextTheme.of(context).labelMedium,
                ),
              ),
            ),
          )
        ],
      ),
      onTap: () {},
    );
  }
}
