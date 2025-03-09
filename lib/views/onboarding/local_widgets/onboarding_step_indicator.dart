part of 'onboarding_template.dart';

class _OnboardingStepIndicator extends StatelessWidget {
  const _OnboardingStepIndicator({
    required this.currentStep,
    required this.maxStep,
  });

  final int currentStep;
  final int maxStep;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "onboarding-indicator",
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6.0,
        children: List.generate(maxStep, (index) {
          Color color = ColorScheme.of(context).onSurface;
          int stepPosition = index + 1;

          final map = {
            0: 1.0,
            1: 0.5,
            2: 0.3,
            3: 0.1,
          };

          final opacity = map[(stepPosition - currentStep).abs()];
          return buildDot(context, color.withValues(alpha: opacity));
        }),
      ),
    );
  }

  Widget buildDot(BuildContext context, Color color) {
    return Container(
      width: 6.0,
      height: 6.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
