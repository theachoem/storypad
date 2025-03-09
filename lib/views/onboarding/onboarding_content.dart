part of 'onboarding_view.dart';

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent(this.viewModel);

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(forceMaterialTransparency: true),
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
        SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: Assets.images.storypadLogo512x512.image(
            width: 150,
            height: 150,
          ),
        ),
        SizedBox(height: 16),
        Text(
          tr("dialog.what_should_i_call_you.title"),
          style: TextTheme.of(context).titleLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.0),
        Text(
          tr("dialog.what_should_i_call_you.message"),
          style: TextTheme.of(context).bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.0),
        _NicknameField(viewModel: viewModel),
        SizedBox(height: 16.0),
        _NextButton(viewModel: viewModel),
      ].asMap().entries.map((entry) {
        return SpFadeIn.fromTop(
          delay: Durations.medium1 * entry.key,
          duration: Durations.medium4,
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
