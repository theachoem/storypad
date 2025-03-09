part of 'onboarding_step_2_view.dart';

class _OnboardingStep2Content extends StatelessWidget {
  const _OnboardingStep2Content(this.viewModel);

  final OnboardingStep2ViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
      ),
    );
  }
}
