// ignore_for_file: constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/animated_route_helper.dart' show AnimatedRouteHelper, SharedAxisTransitionType;
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

enum SpPinUnlockTitle {
  enter_your_pin,
  confirm_your_pin,
  must_be_4_or_6_digits,
  incorrect_pin;

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

class SpPinUnlock extends StatefulWidget {
  const SpPinUnlock({
    super.key,
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

  factory SpPinUnlock.confirmation({
    required BuildContext context,
    required String correctPin,
    SpPinUnlockTitle title = SpPinUnlockTitle.enter_your_pin,
    SpPinUnlockTitle invalidPinTitle = SpPinUnlockTitle.incorrect_pin,
    Future<bool> Function()? onConfirmWithBiometrics,
    void Function(BuildContext context, String? pin)? onValidated,
  }) {
    return SpPinUnlock(
      title: title.translatedTitle,
      invalidPinTitle: invalidPinTitle.translatedTitle,
      validator: (pin) => correctPin == pin,
      onValidated: onValidated ?? (context, _) => Navigator.maybePop(context, true),
      onConfirmWithBiometrics: onConfirmWithBiometrics,
    );
  }

  factory SpPinUnlock.askForPin({
    required BuildContext context,
    SpPinUnlockTitle title = SpPinUnlockTitle.enter_your_pin,
    SpPinUnlockTitle invalidPinTitle = SpPinUnlockTitle.must_be_4_or_6_digits,
    void Function(BuildContext context, String? pin)? onValidated,
  }) {
    return SpPinUnlock(
      title: title.translatedTitle,
      invalidPinTitle: invalidPinTitle.translatedTitle,
      validator: (pin) => pin.length == 4 || pin.length == 4,
      onValidated: onValidated ?? (context, pin) => Navigator.maybePop(context, pin),
    );
  }

  Future<bool> push(BuildContext context) async {
    final nestedNavigation = SpNestedNavigation.maybeOf(context);

    dynamic confirmed;
    if (nestedNavigation != null) {
      confirmed = await nestedNavigation.push(this);
    } else {
      confirmed = await Navigator.of(context).push(
        AnimatedRouteHelper.sharedAxis(
          fullscreenDialog: true,
          type: SharedAxisTransitionType.vertical,
          builder: (context) => this,
        ),
      );
    }

    return confirmed == true;
  }

  Future<bool> pushReplacement(BuildContext context) async {
    final nestedNavigation = SpNestedNavigation.maybeOf(context);

    dynamic confirmed;
    if (nestedNavigation != null) {
      confirmed = await nestedNavigation.pushReplacement(this);
    } else {
      confirmed = await Navigator.of(context).pushReplacement(
        AnimatedRouteHelper.sharedAxis(
          fullscreenDialog: true,
          type: SharedAxisTransitionType.vertical,
          builder: (context) => this,
        ),
      );
    }

    return confirmed == true;
  }

  @override
  State<SpPinUnlock> createState() => _SpPinUnlockState();
}

class _SpPinUnlockState extends State<SpPinUnlock> {
  String pin = "";

  void addPin(int pinItem) async {
    if (pin.length >= 6) return;

    pin += pinItem.toString();
    setState(() {});

    if (widget.validator(pin)) {
      widget.onValidated(context, pin);
    }
  }

  void removeLastPin() {
    pin = pin.substring(0, pin.length - 1);
    setState(() {});
  }

  Future<void> confirmWithBiometrics() async {
    final authenticated = await widget.onConfirmWithBiometrics!.call();
    final context = this.context;
    if (context.mounted && authenticated) widget.onValidated(context, null);
  }

  @override
  void initState() {
    super.initState();

    if (widget.onConfirmWithBiometrics != null) {
      Future.microtask(() {
        confirmWithBiometrics();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double itemSize = MediaQuery.textScalerOf(context).scale(72.0);
      final double spacing = MediaQuery.textScalerOf(context).scale(16.0);
      final double pinSize = MediaQuery.textScalerOf(context).scale(16.0);

      bool landscape = constraints.maxWidth > constraints.maxHeight;
      bool displayInRow = landscape && constraints.maxHeight < 700;

      final children = [
        Flexible(child: buildPinPreview(context, pinSize)),
        Flexible(child: FittedBox(child: buildPins(itemSize, spacing, context))),
      ];

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(forceMaterialTransparency: true),
        body: displayInRow ? Row(children: children) : Column(children: children),
      );
    });
  }

  Widget buildPinPreview(BuildContext context, double pinSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 24),
        (pin.length >= 4) && !widget.validator(pin)
            ? Text(
                widget.invalidPinTitle,
                style: TextTheme.of(context).titleLarge,
                textAlign: TextAlign.center,
              )
            : Text(
                widget.title,
                style: TextTheme.of(context).titleLarge,
                textAlign: TextAlign.center,
              ),
        SizedBox(height: 24),
        SizedBox(
          height: pinSize,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: pinSize,
            children: List.generate(pin.length, (index) {
              final bool invalid = pin.length >= 4 && !widget.validator(pin);
              return Visibility(
                visible: pin.length > index,
                child: SpFadeIn.bound(
                  child: Container(
                    width: pinSize,
                    height: pinSize,
                    decoration: BoxDecoration(
                      color: invalid ? ColorScheme.of(context).error : ColorScheme.of(context).primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget buildPins(double itemSize, double spacing, BuildContext context) {
    return SizedBox(
      width: itemSize * 3 + spacing * 2,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(12, (index) {
          Widget? child;
          Color? backgroundColor = ColorScheme.of(context).readOnly.surface1;
          void Function()? onPressed;

          if (index < 9) {
            int pin = index + 1;
            onPressed = () => addPin(pin);

            child = Container(
              width: itemSize,
              constraints: BoxConstraints(minHeight: itemSize),
              alignment: Alignment.center,
              child: Text(
                pin.toString(),
                style: TextTheme.of(context).headlineMedium,
                textAlign: TextAlign.center,
              ),
            );
          } else if (index == 9) {
            if (widget.onConfirmWithBiometrics != null) {
              onPressed = () => confirmWithBiometrics();
              backgroundColor = null;

              child = Container(
                width: itemSize,
                constraints: BoxConstraints(minHeight: itemSize),
                alignment: Alignment.center,
                child: Icon(
                  Icons.fingerprint,
                  size: itemSize / 2 - 4.0,
                ),
              );
            }
          } else if (index == 10) {
            onPressed = () => addPin(0);
            child = Container(
              width: itemSize,
              constraints: BoxConstraints(minHeight: itemSize),
              alignment: Alignment.center,
              child: Text(
                "0",
                style: TextTheme.of(context).headlineSmall,
                textAlign: TextAlign.center,
              ),
            );
          } else if (index == 11) {
            onPressed = pin.isEmpty ? () {} : () => removeLastPin();
            backgroundColor = null;
            child = Container(
              width: itemSize,
              constraints: BoxConstraints(minHeight: itemSize),
              alignment: Alignment.center,
              child: Icon(Icons.backspace, size: itemSize / 2 - 8.0),
            );
          }

          if (child == null) {
            return SizedBox(
              width: itemSize,
            );
          }

          return Material(
            color: backgroundColor,
            shape: CircleBorder(),
            child: InkWell(
              customBorder: CircleBorder(),
              onTap: onPressed != null
                  ? () {
                      HapticFeedback.selectionClick();
                      onPressed!();
                    }
                  : null,
              child: child,
            ),
          );
        }),
      ),
    );
  }
}
