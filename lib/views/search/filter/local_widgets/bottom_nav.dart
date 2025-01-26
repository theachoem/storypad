part of '../search_filter_view.dart';

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.viewModel,
  });

  final SearchFilterViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
              .add(EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)),
          child: Row(
            spacing: 8.0,
            children: [
              FilledButton.tonalIcon(
                icon: Icon(Icons.clear),
                label: const Text("Clear"),
                onPressed: () => viewModel.reset(context),
              ),
              FilledButton.icon(
                icon: Icon(Icons.search),
                label: const Text("Search"),
                onPressed: () => viewModel.search(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
