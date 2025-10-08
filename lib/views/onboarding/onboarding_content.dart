part of 'onboarding_view.dart';

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent(this.viewModel);

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          forceMaterialTransparency: true,
          actions: [
            IconButton(
              tooltip: tr("page.language.title"),
              icon: const Icon(SpIcons.globe),
              onPressed: () => LanguagesRoute(
                showBetaBanner: false,
                showThemeFAB: true,
                fromOnboarding: true,
              ).push(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          reverse: true,
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: buildContents(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContents(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children:
          [
            Container(
              margin: const EdgeInsets.only(top: 36),
              width: double.infinity,
              child: Assets.images.storypadLogo512x512.image(
                width: 120,
                height: 120,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: Text(
                tr("dialog.what_should_i_call_you.title"),
                style: TextTheme.of(context).titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Text(
                tr("dialog.what_should_i_call_you.message"),
                style: TextTheme.of(context).bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 32),
              child: _NicknameField(viewModel: viewModel),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: _NextButton(viewModel: viewModel),
            ),
          ].asMap().entries.map((entry) {
            return SpFadeIn.fromTop(
              delay: Durations.medium1 * entry.key,
              duration: Durations.long3,
              child: entry.value,
            );
          }).toList(),
    );
  }
}
