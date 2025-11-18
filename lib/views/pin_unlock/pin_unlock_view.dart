// ignore_for_file: constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'pin_unlock_view_model.dart';

part 'pin_unlock_content.dart';

enum PinUnlockTitle {
  enter_your_pin,
  confirm_your_pin,
  must_be_4_or_6_digits,
  incorrect_pin
  ;

  String get translatedTitle {
    switch (this) {
      case enter_your_pin:
        return tr('general.pin_unlock_title.enter_your_pin');
      case confirm_your_pin:
        return tr('general.pin_unlock_title.confirm_your_pin');
      case must_be_4_or_6_digits:
        return tr('general.pin_unlock_title.must_be_4_or_6_digits');
      case incorrect_pin:
        return tr('general.pin_unlock_title.incorrect_pin');
    }
  }
}

class PinUnlockRoute extends BaseRoute {
  const PinUnlockRoute({
    required this.title,
    required this.invalidPinTitle,
    required this.validator,
    required this.onValidated,
    this.onConfirmWithBiometrics,
  });

  final String title;
  final String invalidPinTitle;
  final bool Function(String pin) validator;
  final void Function(BuildContext context, String? pin) onValidated;
  final Future<bool> Function()? onConfirmWithBiometrics;

  @override
  bool get fullscreenDialog => true;

  factory PinUnlockRoute.confirmation({
    required BuildContext context,
    required String correctPin,
    PinUnlockTitle title = PinUnlockTitle.enter_your_pin,
    PinUnlockTitle invalidPinTitle = PinUnlockTitle.incorrect_pin,
    Future<bool> Function()? onConfirmWithBiometrics,
    void Function(BuildContext context, String? pin)? onValidated,
  }) {
    return PinUnlockRoute(
      title: title.translatedTitle,
      invalidPinTitle: invalidPinTitle.translatedTitle,
      validator: (pin) => correctPin == pin,
      onValidated: onValidated ?? (context, _) => Navigator.maybePop(context, true),
      onConfirmWithBiometrics: onConfirmWithBiometrics,
    );
  }

  factory PinUnlockRoute.askForPin({
    required BuildContext context,
    PinUnlockTitle title = PinUnlockTitle.enter_your_pin,
    PinUnlockTitle invalidPinTitle = PinUnlockTitle.must_be_4_or_6_digits,
    void Function(BuildContext context, String? pin)? onValidated,
  }) {
    return PinUnlockRoute(
      title: title.translatedTitle,
      invalidPinTitle: invalidPinTitle.translatedTitle,
      validator: (pin) => pin.length == 4 || pin.length == 4,
      onValidated: onValidated ?? (context, pin) => Navigator.maybePop(context, pin),
    );
  }

  @override
  Widget buildPage(BuildContext context) => PinUnlockView(params: this);
}

class PinUnlockView extends StatelessWidget {
  const PinUnlockView({
    super.key,
    required this.params,
  });

  final PinUnlockRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<PinUnlockViewModel>(
      create: (context) => PinUnlockViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _PinUnlockContent(viewModel);
      },
    );
  }
}
