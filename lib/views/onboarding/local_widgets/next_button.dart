part of "../onboarding_view.dart";

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.viewModel,
  });

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Builder(builder: (context) {
        if (kIsCupertino) {
          return CupertinoButton.filled(
            disabledColor: Theme.of(context).disabledColor,
            sizeStyle: CupertinoButtonSize.medium,
            child: Text(tr("button.next")),
            onPressed: () => viewModel.next(context),
          );
        } else {
          return SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
              child: Text(tr("button.next")),
              onPressed: () => viewModel.next(context),
            ),
          );
        }
      }),
    );
  }
}
