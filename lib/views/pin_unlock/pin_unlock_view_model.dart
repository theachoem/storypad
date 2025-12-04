import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'pin_unlock_view.dart';

class PinUnlockViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PinUnlockRoute params;
  final BuildContext context;
  final FocusNode focusNode = FocusNode();

  PinUnlockViewModel({
    required this.params,
    required this.context,
  }) {
    if (params.onConfirmWithBiometrics != null) {
      Future.microtask(() {
        if (context.mounted) confirmWithBiometrics(context);
      });
    }
  }

  String pin = "";

  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final character = event.character;
      if (character != null && character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57) {
        // Number key 0-9
        final number = int.parse(character);
        addPin(context, number);
      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.backspace)) {
        // Backspace - remove last digit (auto-repeats when held like keyboard)
        removeLastPin();
      } else if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.enter)) {
        // Enter key - attempt to validate
        if (pin.isNotEmpty && pin.length >= 4) {
          if (params.validator(pin)) params.onValidated(context, pin);
        }
      }
    }
  }

  void addPin(BuildContext context, int pinItem) async {
    if (pin.length >= 6) return;

    pin += pinItem.toString();
    notifyListeners();

    if (params.validator(pin)) {
      params.onValidated(context, pin);
    }
  }

  void removeLastPin() {
    if (pin.isEmpty) return;

    pin = pin.substring(0, pin.length - 1);
    notifyListeners();
  }

  Future<void> confirmWithBiometrics(BuildContext context) async {
    final authenticated = await params.onConfirmWithBiometrics!.call();
    if (context.mounted && authenticated) params.onValidated(context, null);
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
}
