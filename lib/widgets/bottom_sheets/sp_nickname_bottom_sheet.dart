import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart' show kAppLogo, kIsCupertino, kStoryPad;
import 'package:storypad/core/services/app_logo_service.dart';
import 'package:storypad/core/types/app_logo.dart';
import 'package:storypad/providers/nickname_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_app_logo_picker.dart';
import 'package:storypad/widgets/sp_default_text_controller.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_two_value_listenable_builder.dart';

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
    ValueNotifier<AppLogo> appLogoNotifier,
  ) async {
    bool logoChanged = nickname == controller.text.trim() && appLogoNotifier.value != kAppLogo;
    bool nicknameChanged = nickname != controller.text.trim() && controller.text.trim().isNotEmpty;

    if (logoChanged || nicknameChanged) {
      context.read<NicknameProvider>().setNickname(controller.text.trim());

      await AppLogoService().set(appLogoNotifier.value);
      if (context.mounted) Navigator.maybePop(context);

      return;
    }
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget(
      initialValue: kAppLogo!,
      builder: (context, appLogoNotifier) {
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
                  buildNicknameField(context, controller, appLogoNotifier),
                  const SizedBox(height: 8.0),
                  if (kStoryPad) ...[
                    const SizedBox(height: 4.0),
                    buildLogoSelector(context, appLogoNotifier),
                    kIsCupertino ? const SizedBox(height: 12.0) : const SizedBox(height: 8.0),
                  ],
                  buildSaveButton(context, controller, appLogoNotifier),
                  buildBottomPadding(bottomPadding),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildNicknameField(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<AppLogo> appLogoNotifier,
  ) {
    if (kIsCupertino) {
      return buildCupertinoField(context, controller, appLogoNotifier);
    } else {
      return buildMaterialField(context, controller, appLogoNotifier);
    }
  }

  Widget buildLogoSelector(BuildContext context, ValueNotifier<AppLogo> appLogoNotifier) {
    return ValueListenableBuilder(
      valueListenable: appLogoNotifier,
      builder: (context, appLogo, child) {
        return SpAppLogoPicker(
          selectedAppLogo: appLogo,
          onLogoSelected: (logo) => appLogoNotifier.value = logo,
        );
      },
    );
  }

  Widget buildSaveButton(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<AppLogo> appLogoNotifier,
  ) {
    return SizedBox(
      width: double.infinity,
      child: SpTwoValueListenableBuilder(
        valueListenable1: controller,
        valueListenable2: appLogoNotifier,
        builder: (context, nicknameValue, appLogoValue, child) {
          bool unchanged =
              (nicknameValue.text.trim().isEmpty || nicknameValue.text.trim() == nickname) && appLogoValue == kAppLogo;

          if (kIsCupertino) {
            return CupertinoButton.filled(
              disabledColor: Theme.of(context).disabledColor,
              sizeStyle: CupertinoButtonSize.medium,
              onPressed: unchanged ? null : () => save(context, controller, appLogoNotifier),
              child: nickname == null ? Text(tr("button.save")) : Text(tr("button.update")),
            );
          } else {
            return FilledButton(
              onPressed: unchanged ? null : () => save(context, controller, appLogoNotifier),
              child: nickname == null ? Text(tr("button.save")) : Text(tr("button.update")),
            );
          }
        },
      ),
    );
  }

  TextFormField buildMaterialField(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<AppLogo> appLogoNotifier,
  ) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.trim().isEmpty) return tr("general.required");
        return null;
      },
      controller: controller,
      onFieldSubmitted: (value) => save(context, controller, appLogoNotifier),
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.name,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: tr("input.nickname.hint"),
      ),
    );
  }

  FormField<String> buildCupertinoField(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<AppLogo> appLogoNotifier,
  ) {
    return FormField<String>(
      validator: (value) {
        if (value == null || value.trim().isEmpty) return tr("general.required");
        return null;
      },
      builder: (state) {
        return CupertinoTextField(
          controller: controller,
          onSubmitted: (value) => save(context, controller, appLogoNotifier),
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
