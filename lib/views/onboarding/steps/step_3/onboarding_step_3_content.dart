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
      demo: FadeInBuilder(
        transformBuilder: (a) => Matrix4.identity()..translate(0.0, lerpDouble(64.0, 0.0, a.value)!),
        duration: Duration(milliseconds: 1000),
        child: HomeScreenshot(
          child: Stack(
            children: [
              buildEndDrawerBarrier(),
              buildEndDrawerDemo(),
              VisibleWhenNotified(
                notifier: viewModel.showSignInClickedNotifier,
                child: ClickAnimation(
                  left: 0,
                  right: 0,
                  top: 204,
                  clickDuration: viewModel.clickDuration,
                ),
              ),
              VisibleWhenNotified(
                notifier: viewModel.showSyncClickedNotifier,
                child: ClickAnimation(
                  left: 0,
                  right: 16,
                  top: 204,
                  clickDuration: viewModel.clickDuration,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEndDrawerDemo() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: VisibleWhenNotified(
        notifier: viewModel.endDrawerOpenedNotifier,
        child: ClipRRect(
          borderRadius: BorderRadius.only(topRight: Radius.circular(12.0)),
          child: FadeInBuilder(
            curve: Curves.ease,
            duration: viewModel.endDrawerFadeInDuration,
            transformBuilder: (a) => Matrix4.identity()..translate(lerpDouble(221.0, 0.0, a.value)!, 0.0),
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              controller: viewModel.endDrawerScrollController,
              child: ValueListenableBuilder(
                valueListenable: viewModel.endDrawerStateNotifier,
                builder: (context, state, child) {
                  return EndDrawerScreenshot(state: state);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEndDrawerBarrier() {
    return VisibleWhenNotified(
      notifier: viewModel.endDrawerOpenedNotifier,
      child: SpFadeIn(
        curve: Curves.fastEaseInToSlowEaseOut,
        testCurves: false,
        duration: Duration(seconds: 1),
        child: Container(
          width: 300,
          height: 360,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
          ),
        ),
      ),
    );
  }

  Widget buildActionButton(BuildContext context) {
    if (AppTheme.isCupertino(context)) {
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
