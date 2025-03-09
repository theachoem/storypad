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
              icon: Icon(Icons.language_outlined),
              onPressed: () => LanguagesRoute(showBetaBanner: false).push(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          reverse: true,
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
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
      children: [
        Container(
          margin: EdgeInsets.only(top: 36),
          width: double.infinity,
          child: Assets.images.storypadLogo512x512.image(
            width: 120,
            height: 120,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 16),
          child: Text(
            tr("dialog.what_should_i_call_you.title"),
            style: TextTheme.of(context).titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 8),
          child: Text(
            tr("dialog.what_should_i_call_you.message"),
            style: TextTheme.of(context).bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 32),
          child: _NicknameField(viewModel: viewModel),
        ),
        Container(
          margin: EdgeInsets.only(top: 16),
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

class _NicknameField extends StatelessWidget {
  const _NicknameField({
    required this.viewModel,
  });

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '';
        return null;
      },
      builder: (state) {
        InputBorder border = OutlineInputBorder(
          borderSide: state.hasError
              ? BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0)
              : BorderSide(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12.0),
        );

        return TextFormField(
          onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
          onFieldSubmitted: (value) => viewModel.next(context),
          controller: viewModel.controller,
          textAlign: TextAlign.center,
          onChanged: (value) => state.didChange(value),
          decoration: InputDecoration(
            border: border,
            enabledBorder: border,
            focusedBorder: border,
            hintText: tr("input.nickname.hint"),
          ),
        );
      },
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.viewModel,
  });

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: Builder(builder: (context) {
        return FilledButton(
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
          child: Text(tr("button.next")),
          onPressed: () => viewModel.next(context),
        );
      }),
    );
  }
}
