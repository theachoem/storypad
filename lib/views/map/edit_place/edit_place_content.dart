part of 'edit_place_view.dart';

class _EditPlaceContent extends StatelessWidget {
  const _EditPlaceContent(this.viewModel);

  final EditPlaceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.map.edit_place.title")),
        actions: [
          FilledButton(
            onPressed: viewModel.canApply ? () => viewModel.apply(context) : null,
            child: Text(tr("button.apply")),
          ),
          const SizedBox(width: 12.0),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 16.0,
          left: MediaQuery.paddingOf(context).left,
          right: MediaQuery.paddingOf(context).right,
          bottom: MediaQuery.paddingOf(context).bottom + 16.0,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: viewModel.labelController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: viewModel.onLabelChanged,
              onSubmitted: (_) {
                if (viewModel.canApply) {
                  viewModel.apply(context);
                }
              },
              decoration: InputDecoration(
                labelText: tr("input.place_name.label"),
                hintText: tr("input.place_name.hint"),
              ),
            ),
          ),
          if (viewModel.recentLabels.isNotEmpty) ...[
            const SizedBox(height: 16),
            SpSectionTitle(
              title: tr("page.map.edit_place.recent_labels"),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Wrap(
                spacing: 8,
                children: viewModel.recentLabels
                    .map(
                      (label) => ActionChip(
                        label: Text(label),
                        onPressed: () => viewModel.useLabelSuggestion(label),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
