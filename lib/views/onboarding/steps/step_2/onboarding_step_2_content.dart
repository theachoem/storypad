part of 'onboarding_step_2_view.dart';

class _OnboardingStep2Content extends StatelessWidget {
  const _OnboardingStep2Content(this.viewModel);

  final OnboardingStep2ViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = ColorScheme.of(context).brightness == Brightness.dark;

    return OnboardingTemplate(
      title: tr("page.onboarding_step2.title"),
      description: tr("page.onboarding_step2.description"),
      currentStep: 2,
      maxStep: 4,
      actionButton: buildActionButton(context),
      onSkip: () => viewModel.skip(context),
      demo: Stack(
        children: [
          VisibleWhenNotified(
            notifier: viewModel.showStoryDetailsPageNotifier,
            child: FadeInBuilder(
              duration: viewModel.storyDetailsAnimationDuration,
              transformBuilder: (a) => Matrix4.identity()..spTranslate(0.0, lerpDouble(64.0, 0.0, a.value)!),
              child: const StoryDetailsScreenshot(),
            ),
          ),
          buildFeelingButton(),
          buildFeelingClickAnimation(),
          buildToolbar(isDarkMode),
        ],
      ),
    );
  }

  Widget buildToolbar(bool isDarkMode) {
    return VisibleWhenNotified(
      notifier: viewModel.showToolbarNotifier,
      child: Positioned(
        left: 1,
        right: 1,
        bottom: 0,
        child: FadeInBuilder(
          duration: viewModel.toolbarFadeInDuration,
          transformBuilder: (a) => Matrix4.identity()..spTranslate(0.0, lerpDouble(64.0, 0.0, a.value)!),
          child: SizedBox(
            height: 42,
            child: SingleChildScrollView(
              reverse: true,
              scrollDirection: Axis.horizontal,
              controller: viewModel.toolbarScrollController,
              child:
                  (isDarkMode
                          ? Assets.images.onboarding.toolbarDark1690x70
                          : Assets.images.onboarding.toolbarLight1690x70)
                      .image(height: 44),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFeelingClickAnimation() {
    return VisibleWhenNotified(
      notifier: viewModel.feelingClickedNotifier,
      child: ClickAnimation(
        clickDuration: viewModel.feelingClickDuration,
        top: 49,
        right: 1,
      ),
    );
  }

  Widget buildFeelingButton() {
    return Positioned(
      top: 57,
      right: 0,
      child: VisibleWhenNotified(
        notifier: viewModel.showFeelingButtonNotifier,
        child: SpFadeIn(
          duration: viewModel.feelingButtonFadeInDuration,
          child: Transform(
            transform: Matrix4.identity()
              ..spTranslate(9.0, 0.0)
              ..scaleAdjoint(0.74),
            child: ValueListenableBuilder(
              valueListenable: viewModel.selectedFeelingNotifier,
              builder: (context, feeling, child) {
                return SpFeelingButton(
                  feeling: feeling,
                  onPicked: (feeling) async => viewModel.selectedFeelingNotifier.value = feeling,
                );
              },
            ),
          ),
        ),
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
