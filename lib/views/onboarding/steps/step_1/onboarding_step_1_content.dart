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
      onSkip: () => viewModel.skip(context),
      demo: Stack(
        children: [
          VisibleWhenNotified(
            notifier: viewModel.showHomePageNotifier,
            child: FadeInBuilder(
              transformBuilder: (a) => Matrix4.identity()..spTranslate(0.0, lerpDouble(64.0, 0.0, a.value)!),
              duration: const Duration(milliseconds: 1000),
              child: const HomeScreenshot(),
            ),
          ),
          VisibleWhenNotified(
            notifier: viewModel.showStoryDetailsPageNotifier,
            child: FadeInBuilder(
              duration: viewModel.storyDetailsAnimationDuration,
              transformBuilder: (a) => Matrix4.identity()..spTranslate(0.0, lerpDouble(360.0, 0.0, a.value)!),
              child: const StoryDetailsScreenshot(),
            ),
          ),
          VisibleWhenNotified(
            notifier: viewModel.showStoryClickedNotifier,
            child: const ClickAnimation(
              left: 0,
              right: 0,
              top: 188,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        disabledColor: Theme.of(context).disabledColor,
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => viewModel.next(context),
        child: Text(tr("button.next")),
      );
    } else {
      return OutlinedButton(
        child: Text(tr("button.next")),
        onPressed: () => viewModel.next(context),
      );
    }
  }
}
