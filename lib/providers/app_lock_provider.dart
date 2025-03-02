import 'package:easy_localization/easy_localization.dart' show tr;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/app_lock_object.dart' show $AppLockObjectCopyWith, AppLockObject;
import 'package:storypad/core/services/local_auth_service.dart' show LocalAuthService;
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/storages/app_lock_storage.dart' show AppLockStorage;
import 'package:storypad/core/types/app_lock_question.dart' show AppLockQuestion;
import 'package:storypad/views/app_locks/security_questions/security_questions_view.dart';
import 'package:storypad/widgets/sp_pin_unlock.dart';

class AppLockProvider extends ChangeNotifier {
  AppLockProvider() {
    load();
  }

  bool get hasAppLock =>
      appLock.pin != null || (localAuth.canCheckBiometrics == true && appLock.enabledBiometric == true);

  final AppLockStorage storage = AppLockStorage();
  final LocalAuthService localAuth = LocalAuthService();

  AppLockObject? _appLock;
  AppLockObject get appLock => _appLock ?? AppLockObject.init();

  Future<void> load() async {
    await localAuth.load();
    _appLock = await storage.readObject();
    notifyListeners();
  }

  Future<void> forceResetPIN(BuildContext context) async {
    await storage.writeObject(appLock.copyWith(pin: null));
    await load();

    if (context.mounted) {
      MessengerService.of(context).showSnackBar("PIN removed");
    }
  }

  Future<void> togglePIN(BuildContext context) async {
    if (appLock.pin == null) {
      await setPIN(context);
    } else {
      await clearPIN(context);
    }
  }

  Future<void> clearPIN(BuildContext context) async {
    bool authenticated = await SpPinUnlock.openConfirmation(
      context: context,
      correctPin: appLock.pin!,
      title: SpPinUnlockTitle.confirm_your_pin,
      invalidPinTitle: SpPinUnlockTitle.incorrect_pin,
    );

    if (context.mounted && authenticated) {
      await storage.writeObject(appLock.copyWith(pin: null));
      await load();
    }
  }

  Future<void> setPIN(BuildContext context) async {
    String? newPin = await SpPinUnlock.askForPin(
      context: context,
      title: SpPinUnlockTitle.enter_your_pin,
      invalidPinTitle: SpPinUnlockTitle.must_be_4_or_6_digits,
    );

    if (context.mounted && newPin != null) {
      bool authenticated = await SpPinUnlock.openConfirmation(
        context: context,
        correctPin: newPin,
        title: SpPinUnlockTitle.confirm_your_pin,
        invalidPinTitle: SpPinUnlockTitle.incorrect_pin,
      );

      if (context.mounted && authenticated) {
        await SecurityQuestionsRoute().push(context);
        if (appLock.securityAnswers?.keys.isNotEmpty == true) {
          await storage.writeObject(appLock.copyWith(pin: newPin));
          await load();
        }
      }
    }
  }

  Future<void> setSecurityAnswer(Map<AppLockQuestion, String> securityAnswers) async {
    await storage.writeObject(appLock.copyWith(securityAnswers: securityAnswers));
    await load();
  }

  Future<void> toggleBiometrics(BuildContext context) async {
    bool authenticated =
        await context.read<AppLockProvider>().localAuth.authenticate(title: tr('dialog.unlock_to_continue.title'));

    if (authenticated) {
      await storage.writeObject(appLock.copyWith(enabledBiometric: !(appLock.enabledBiometric == true)));
      await load();
    }
  }
}
