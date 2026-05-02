part of 'edit_place_view.dart';

class _EditPlaceContent extends StatelessWidget {
  const _EditPlaceContent(this.viewModel);

  final EditPlaceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit place'),
        actions: [
          FilledButton(
            onPressed: viewModel.canApply ? () => viewModel.apply(context) : null,
            child: const Text('Apply'),
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
              decoration: const InputDecoration(
                labelText: 'Place name',
                hintText: 'Coffee shop, park, museum...',
              ),
            ),
          ),
          if (viewModel.recentLabels.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SpSectionTitle(title: "Recent labels"),
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
