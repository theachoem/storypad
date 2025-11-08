part of 'onboarding_step_4_view.dart';

class _OnboardingStep4Content extends StatelessWidget {
  const _OnboardingStep4Content(this.viewModel);

  final OnboardingStep4ViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      title: tr("page.onboarding_step4.title"),
      description: tr("page.onboarding_step4.description"),
      currentStep: 4,
      maxStep: 4,
      actionButton: buildActionButton(context),
      fadeInContent: true,
      onSkip: null,
      demo: null,
    );
  }

  Widget buildActionButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        disabledColor: Theme.of(context).disabledColor,
        sizeStyle: CupertinoButtonSize.medium,
        child: Text(tr("button.get_started")),
        onPressed: () => viewModel.getStarted(context),
      );
    } else {
      return OutlinedButton(
        child: Text(tr("button.get_started")),
        onPressed: () => viewModel.getStarted(context),
      );
    }
  }
}
