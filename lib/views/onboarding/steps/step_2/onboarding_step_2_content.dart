part of 'onboarding_step_2_view.dart';

class _OnboardingStep2Content extends StatelessWidget {
  const _OnboardingStep2Content(this.viewModel);

  final OnboardingStep2ViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      title: tr("page.onboarding_step2.title"),
      description: tr("page.onboarding_step2.description"),
      currentStep: 2,
      maxStep: 4,
      actionButton: buildActionButton(context),
      demo: SizedBox(),
    );
  }

  Widget buildActionButton(BuildContext context) {
    return OutlinedButton(
      child: Text(tr("button.next")),
      onPressed: () => viewModel.next(context),
    );
  }
}
