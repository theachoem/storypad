part of 'onboarding_step_1_view.dart';

class _OnboardingStep1Content extends StatelessWidget {
  const _OnboardingStep1Content(this.viewModel);

  final OnboardingStep1ViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
      ),
    );
  }
}
