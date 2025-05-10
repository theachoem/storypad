import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'pin_unlock_view.dart';

class PinUnlockViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PinUnlockRoute params;

  PinUnlockViewModel({
    required this.params,
    required BuildContext context,
  }) {
    if (params.onConfirmWithBiometrics != null) {
      Future.microtask(() {
        if (context.mounted) confirmWithBiometrics(context);
      });
    }
  }

  String pin = "";

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
}
