import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart' show tr;
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/app_lock_object.dart' show $AppLockObjectCopyWith, AppLockObject;
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/local_auth_service.dart' show LocalAuthService;
import 'package:storypad/core/storages/app_lock_storage.dart' show AppLockStorage;
import 'package:storypad/core/types/app_lock_question.dart' show AppLockQuestion;
import 'package:storypad/initializers/app_lock_initializer.dart';
import 'package:storypad/views/app_locks/security_questions/security_questions_view.dart';
import 'package:storypad/widgets/sp_pin_unlock.dart';

class AppLockProvider extends ChangeNotifier {
  AppLockProvider() {
    final initialData = AppLockInitializer.getAndClear();

    if (initialData != null) {
      _appLock = initialData.appLock;
      _localAuth = initialData.localAuth;
    } else {
      _appLock = AppLockObject.init();
      _localAuth = LocalAuthService();

      reload();
    }
  }

  bool get hasAppLock =>
      appLock.pin != null || (localAuth.canCheckBiometrics == true && appLock.enabledBiometric == true);

  final AppLockStorage storage = AppLockStorage();

  late LocalAuthService _localAuth;
  late AppLockObject _appLock;

  LocalAuthService get localAuth => _localAuth;
  AppLockObject get appLock => _appLock;

  Future<void> reload() async {
    await localAuth.load();
    _appLock = await storage.readObject() ?? _appLock;
    notifyListeners();
  }

  Future<bool> authenticateIfHas(BuildContext context) async {
    if (!hasAppLock) return true;
    if (appLock.pin != null) {
      return SpPinUnlock.confirmation(
        context: context,
        title: SpPinUnlockTitle.enter_your_pin,
        invalidPinTitle: SpPinUnlockTitle.incorrect_pin,
        correctPin: appLock.pin!,
        onConfirmWithBiometrics: localAuth.canCheckBiometrics == true
            ? () => localAuth.authenticate(title: tr('dialog.unlock_to_open_the_app.title'))
            : null,
      ).push(context);
    } else {
      return localAuth.authenticate(title: tr('dialog.unlock_to_open_the_app.title'));
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
    bool authenticated = await SpPinUnlock.confirmation(
      context: context,
      correctPin: appLock.pin!,
      title: SpPinUnlockTitle.confirm_your_pin,
      invalidPinTitle: SpPinUnlockTitle.incorrect_pin,
    ).push(context);

    if (context.mounted && authenticated) {
      AnalyticsService.instance.logClearPIN();
      await storage.writeObject(appLock.copyWith(pin: null));
      await reload();
    }
  }

  Future<void> setPIN(BuildContext context) async {
    SpPinUnlock.askForPin(
      context: context,
      title: SpPinUnlockTitle.enter_your_pin,
      invalidPinTitle: SpPinUnlockTitle.must_be_4_or_6_digits,
      onValidated: (context, pin) => SpPinUnlock.confirmation(
        title: SpPinUnlockTitle.confirm_your_pin,
        context: context,
        correctPin: pin!,
        onValidated: (context, pin) async {
          await SecurityQuestionsRoute().pushReplacement(context);
          if (appLock.securityAnswers?.keys.isNotEmpty == true) {
            AnalyticsService.instance.logSetPIN();
            await storage.writeObject(appLock.copyWith(pin: pin));
            await reload();
          }
        },
      ).pushReplacement(context),
    ).push(context);
  }

  Future<void> setSecurityAnswer(Map<AppLockQuestion, String> securityAnswers) async {
    await storage.writeObject(appLock.copyWith(securityAnswers: securityAnswers));
    await reload();
  }

  Future<void> toggleBiometrics(BuildContext context) async {
    bool authenticated = await localAuth.authenticate(title: tr('dialog.unlock_to_continue.title'));

    if (authenticated) {
      await storage.writeObject(appLock.copyWith(enabledBiometric: !(appLock.enabledBiometric == true)));
      await reload();
    }
  }

  Future<void> forgotPin(BuildContext context) async {
    final questions = appLock.securityAnswers?.keys.toList() ?? [];

    final selectedQuestion = await showConfirmationDialog(
      context: context,
      title: '',
      toggleable: false,
      actions: questions.map((question) {
        return AlertDialogAction(key: question, label: question.translatedQuestion);
      }).toList(),
    );

    if (context.mounted && selectedQuestion != null) {
      final answer = appLock.securityAnswers![selectedQuestion];
      final corrected = await showTextAnswerDialog(
        context: context,
        title: selectedQuestion.translatedQuestion,
        isCaseSensitive: false,
        keyword: answer!,
      );

      if (context.mounted && corrected == true) {
        await storage.writeObject(appLock.copyWith(pin: null));
        await reload();
      }
    }
  }
}
