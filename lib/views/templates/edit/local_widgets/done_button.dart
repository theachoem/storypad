part of '../edit_template_view.dart';

class _DoneButton extends StatelessWidget {
  const _DoneButton({
    required this.viewModel,
  });

  final EditTemplateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpFadeIn.bound(
      child: ValueListenableBuilder(
        valueListenable: viewModel.lastSavedAtNotifier,
        builder: (_, lastSavedAt, child) {
          bool disabled = lastSavedAt == null;
          return OutlinedButton.icon(
            icon: SpAnimatedIcons(
              firstChild: const Icon(SpIcons.save),
              secondChild: const Icon(SpIcons.check),
              showFirst: disabled,
            ),
            label: Text(tr("button.done")),
            // use root context for done, it use for pop.
            // context in this builder will be disposed when readOnly.
            onPressed: disabled ? null : () => viewModel.done(context),
          );
        },
      ),
    );
  }
}
