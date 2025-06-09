part of '../edit_story_view.dart';

class _DoneButton extends StatelessWidget {
  const _DoneButton({
    required this.viewModel,
  });

  final EditStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: viewModel.lastSavedAtNotifier,
      builder: (_, lastSavedAt, child) {
        return Visibility(
          visible: lastSavedAt != null,
          child: SpFadeIn.bound(
            child: OutlinedButton.icon(
              icon: const Icon(SpIcons.check),
              label: Text(tr("button.done")),
              // use root context for done, it use for pop.
              // context in this builder will be disposed when readOnly.
              onPressed: () => viewModel.done(context),
            ),
          ),
        );
      },
    );
  }
}
