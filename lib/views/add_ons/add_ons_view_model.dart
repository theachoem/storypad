import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'add_ons_view.dart';

class AddOnsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final AddOnsRoute params;
  final DevicePreferencesProvider devicePreferencesProvider;

  AddOnsViewModel({
    required this.params,
    required BuildContext context,
  }) : devicePreferencesProvider = context.read<DevicePreferencesProvider>() {
    devicePreferencesProvider.addListenerForAddOnChanges(notifyListeners);
  }

  @override
  void dispose() {
    devicePreferencesProvider.removeListenerForAddOnChanges(notifyListeners);
    super.dispose();
  }
}
