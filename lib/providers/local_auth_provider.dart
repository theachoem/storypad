import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics/analytics_user_propery_service.dart';
import 'package:storypad/core/services/local_auth_service.dart';

class LocalAuthProvider extends ChangeNotifier {
  bool get localAuthEnabled => LocalAuthService.instance.localAuthEnabled;
  bool get canCheckBiometrics => LocalAuthService.instance.canCheckBiometrics;
  bool get shouldShowLock => localAuthEnabled && canCheckBiometrics;

  Future<void> setEnable(bool value) async {
    await LocalAuthService.instance.setEnable(value);

    // notifyListeners will allow all getter variables
    // to alert latest data to UI.
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetLocalAuth(
      enable: value,
    );
  }
}
