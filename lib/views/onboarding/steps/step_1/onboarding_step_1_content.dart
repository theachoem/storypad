part of 'onboarding_step_1_view.dart';

class _OnboardingStep1Content extends StatelessWidget {
  const _OnboardingStep1Content(this.viewModel);

  final OnboardingStep1ViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      title: tr("page.onboarding_step1.title"),
      description: tr("page.onboarding_step1.description"),
      currentStep: 1,
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
