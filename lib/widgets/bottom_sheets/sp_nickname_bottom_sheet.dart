import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_default_text_controller.dart';

class SpNicknameBottomSheet extends BaseBottomSheet {
  const SpNicknameBottomSheet({
    required this.nickname,
  });

  final String? nickname;

  @override
  bool get fullScreen => false;

  Future<void> save(
    BuildContext context,
    TextEditingController controller,
  ) async {
    if (Form.of(context).validate()) {
      Navigator.maybePop(context, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpDefaultTextController(
      initialText: nickname,
      withForm: true,
      builder: (context, controller) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr("dialog.what_should_i_call_you.title"),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
              ),
              Text(
                tr("dialog.what_should_i_call_you.message"),
                overflow: TextOverflow.ellipsis,
                style: TextTheme.of(context).bodyLarge,
                maxLines: 2,
              ),
              const SizedBox(height: 16.0),
              buildNicknameField(context, controller),
              const SizedBox(height: 8.0),
              buildSaveButton(context, controller),
              buildBottomPadding(bottomPadding)
            ],
          ),
        );
      },
    );
  }

  Widget buildNicknameField(BuildContext context, TextEditingController controller) {
    if (AppTheme.isCupertino(context)) {
      return buildCupertinoField(context, controller);
    } else {
      return buildMaterialField(context, controller);
    }
  }

  Widget buildSaveButton(BuildContext context, TextEditingController controller) {
    return SizedBox(
      width: double.infinity,
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, child) {
          bool unchanged = value.text.trim().isEmpty || value.text.trim() == nickname;

          if (AppTheme.isCupertino(context)) {
            return CupertinoButton.filled(
              disabledColor: Theme.of(context).disabledColor,
              sizeStyle: CupertinoButtonSize.medium,
              onPressed: unchanged ? null : () => save(context, controller),
              child: nickname == null ? Text(tr("button.save")) : Text(tr("button.update")),
            );
          } else {
            return FilledButton(
              onPressed: unchanged ? null : () => save(context, controller),
              child: nickname == null ? Text(tr("button.save")) : Text(tr("button.update")),
            );
          }
        },
      ),
    );
  }

  TextFormField buildMaterialField(BuildContext context, TextEditingController controller) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.trim().isEmpty) return tr("general.required");
        return null;
      },
      controller: controller,
      onFieldSubmitted: (value) => save(context, controller),
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.name,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: tr("input.nickname.hint"),
      ),
    );
  }

  FormField<String> buildCupertinoField(BuildContext context, TextEditingController controller) {
    return FormField<String>(
      validator: (value) {
        if (value == null || value.trim().isEmpty) return tr("general.required");
        return null;
      },
      builder: (state) {
        return CupertinoTextField(
          controller: controller,
          onSubmitted: (value) => save(context, controller),
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.name,
          placeholder: tr("input.nickname.hint"),
          onChanged: (value) => state.didChange(value),
          autocorrect: false,
        );
      },
    );
  }
}
