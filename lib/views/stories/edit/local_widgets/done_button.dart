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
        bool disabled = lastSavedAt == null;
        return Visibility(
          visible: (viewModel.flowType == EditingFlowType.create && lastSavedAt != null) ||
              (viewModel.flowType == EditingFlowType.update),
          child: SpFadeIn.bound(
            child: OutlinedButton.icon(
              icon: SpAnimatedIcons(
                firstChild: const Icon(SpIcons.save),
                secondChild: const Icon(SpIcons.check),
                showFirst: disabled,
              ),
              label: Text(tr("button.done")),
              // use root context for done, it use for pop.
              // context in this builder will be disposed when readOnly.
              onPressed: disabled ? null : () => viewModel.done(context),
            ),
          ),
        );
      },
    );
  }
}
