import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_default_text_controller.dart';

class SpNicknameBottomSheet extends BaseBottomSheet {
  const SpNicknameBottomSheet({
    required this.nickname,
  });

  final String? nickname;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpDefaultTextController(
      initialText: nickname,
      withForm: true,
      builder: (context, controller) {
        Future<void> save() async {
          if (Form.of(context).validate()) {
            Navigator.maybePop(context, controller.text.trim());
          }
        }

        return Container(
          width: double.infinity,
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
              TextFormField(
                controller: controller,
                onFieldSubmitted: (value) => save(),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return tr("general.required");
                  return null;
                },
                decoration: InputDecoration(
                  hintText: tr("input.nickname.hint"),
                ),
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    bool unchanged = value.text.trim().isEmpty || value.text.trim() == nickname;
                    return FilledButton(
                      onPressed: unchanged ? null : () => save(),
                      child: nickname == null ? Text(tr("button.save")) : Text(tr("button.update")),
                    );
                  },
                ),
              ),
              buildBottomPadding(bottomPadding)
            ],
          ),
        );
      },
    );
  }
}
