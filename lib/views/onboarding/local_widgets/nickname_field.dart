part of '../onboarding_view.dart';

class _NicknameField extends StatelessWidget {
  const _NicknameField({
    required this.viewModel,
  });

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: viewModel.controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '';
        return null;
      },
      builder: (state) {
        if (kIsCupertino) {
          return buildCupertinoField(state, context);
        } else {
          return buildMaterialField(state, context);
        }
      },
    );
  }

  TextFormField buildMaterialField(FormFieldState<String> state, BuildContext context) {
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
  }

  CupertinoTextField buildCupertinoField(FormFieldState<String> state, BuildContext context) {
    BoxDecoration decoration;

    if (state.hasError) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      );
    } else {
      // base on [_kDefaultRoundedBorderDecoration]
      decoration = BoxDecoration(
        color: const CupertinoDynamicColor.withBrightness(
          color: CupertinoColors.white,
          darkColor: CupertinoColors.black,
        ),
        border: Border.all(
          width: 0.0,
          color: const CupertinoDynamicColor.withBrightness(
            color: Color(0x33000000),
            darkColor: Color(0x33FFFFFF),
          ),
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(5.0),
        ),
      );
    }

    return CupertinoTextField(
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      onSubmitted: (value) => viewModel.next(context),
      controller: viewModel.controller,
      textAlign: TextAlign.center,
      onChanged: (value) => state.didChange(value),
      decoration: decoration,
      placeholder: tr("input.nickname.hint"),
    );
  }
}
