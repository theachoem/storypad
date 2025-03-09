part of 'onboarding_step_3_view.dart';

class _OnboardingStep3Content extends StatelessWidget {
  const _OnboardingStep3Content(this.viewModel);

  final OnboardingStep3ViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      title: tr('page.onboarding_step3.title'),
      description: tr('page.onboarding_step3.description'),
      currentStep: 3,
      maxStep: 4,
      actionButton: buildActionButton(context),
      demo: HomeScreenshot(),
    );
  }

  Widget buildActionButton(BuildContext context) {
    return OutlinedButton(
      child: Text(tr("button.next")),
      onPressed: () => viewModel.next(context),
    );
  }
}
