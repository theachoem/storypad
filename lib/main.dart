import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' show EasyLocalization;
import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseOptions;
import 'package:macos_window_utils/window_manipulator.dart' show WindowManipulator;
import 'package:storypad/app.dart' show App;
import 'package:storypad/core/initializers/app_lock_initializer.dart' show AppLockInitializer;
import 'package:storypad/core/initializers/backup_initializer.dart' show BackupRepositoryInitializer;
import 'package:storypad/core/initializers/constants_initializer.dart' show ConstantsInitializer;
import 'package:storypad/core/initializers/database_initializer.dart' show DatabaseInitializer;
import 'package:storypad/core/initializers/firebase_crashlytics_initializer.dart' show FirebaseCrashlyticsInitializer;
import 'package:storypad/core/initializers/firebase_remote_config_initializer.dart'
    show FirebaseRemoteConfigInitializer;
import 'package:storypad/core/initializers/firestore_storage_initializer.dart';
import 'package:storypad/core/initializers/legacy_storypad_initializer.dart' show LegacyStoryPadInitializer;
import 'package:storypad/core/initializers/licenses_initializer.dart' show LicensesInitializer;
import 'package:storypad/core/initializers/onboarding_initializer.dart' show OnboardingInitializer;
import 'package:storypad/core/initializers/theme_initializer.dart' show ThemeInitializer;
import 'package:storypad/provider_scope.dart' show ProviderScope;

void main({
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tempoary workaround until this is fixed:
  // https://github.com/flutter/flutter/issues/175606#issuecomment-3576240885
  if (Platform.isIOS) _installZeroOffsetPointerGuard();

  // firebase initialize
  await Firebase.initializeApp(options: firebaseOptions);
  FirebaseCrashlyticsInitializer.call();
  FirebaseRemoteConfigInitializer.call();

  // core
  await EasyLocalization.ensureInitialized();
  await ConstantsInitializer.call();
  await DatabaseInitializer.call();
  await AppLockInitializer.call();
  await BackupRepositoryInitializer.call();

  // ui
  await ThemeInitializer.call();
  await LegacyStoryPadInitializer.call();
  await OnboardingInitializer.call();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (Platform.isMacOS) {
    await WindowManipulator.initialize();
    await WindowManipulator.makeTitlebarTransparent();
    await WindowManipulator.hideTitle();
    await WindowManipulator.enableFullSizeContentView();
  }

  // initialize & cleanup old assets
  await FirestoreStorageInitializer.call();

  LicensesInitializer.call();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

bool _zeroOffsetPointerGuardInstalled = false;
void _installZeroOffsetPointerGuard() {
  if (_zeroOffsetPointerGuardInstalled) return;
  GestureBinding.instance.pointerRouter.addGlobalRoute(_absorbZeroOffsetPointerEvent);
  _zeroOffsetPointerGuardInstalled = true;
}

void _absorbZeroOffsetPointerEvent(PointerEvent event) {
  if (event.position == Offset.zero) {
    GestureBinding.instance.cancelPointer(event.pointer);
  }
}
