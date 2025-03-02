import 'package:flutter/material.dart';
import 'package:storypad/core/objects/app_lock_object.dart' show $AppLockObjectCopyWith, AppLockObject;
import 'package:storypad/core/services/local_auth_service.dart' show LocalAuthService;
import 'package:storypad/core/storages/app_lock_storage.dart' show AppLockStorage;
import 'package:storypad/core/types/app_lock_question.dart' show AppLockQuestion;

class AppLockProvider extends ChangeNotifier {
  AppLockProvider() {
    load();
  }

  bool get shouldShowLock => true;

  final AppLockStorage storage = AppLockStorage();
  final LocalAuthService localAuth = LocalAuthService();

  AppLockObject? _appLock;
  AppLockObject get appLock => _appLock ?? AppLockObject.init();

  Future<void> load() async {
    await localAuth.load();
    _appLock = await storage.readObject();
    notifyListeners();
  }

  Future<void> togglePIN(BuildContext context) async {}

  Future<void> setSecurityAnswer(Map<AppLockQuestion, String> securityAnswers) async {
    await storage.writeObject(appLock.copyWith(securityAnswers: securityAnswers));
    await load();
  }

  Future<void> toggleBiometrics() async {
    await storage.writeObject(appLock.copyWith(enabledBiometric: !(appLock.enabledBiometric == true)));
    await load();
  }
}
