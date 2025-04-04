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
        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).add(EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
              left: MediaQuery.of(context).padding.left,
              right: MediaQuery.of(context).padding.right,
            )),
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              spacing: 8.0,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(SpIcons.clear),
                  label: Text(tr("button.clear")),
                  onPressed: viewModel.filtered ? () => viewModel.reset(context) : null,
                ),
                FilledButton.icon(
                  icon: const Icon(SpIcons.search),
                  label: Text(tr("button.search")),
                  onPressed: () => viewModel.search(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
