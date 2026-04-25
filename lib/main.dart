import 'dart:io';
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
import 'package:storypad/core/initializers/crashlytics_initializer.dart' show CrashlyticsInitializer;
import 'package:storypad/core/initializers/remote_config_initializer.dart' show RemoteConfigInitializer;
import 'package:storypad/core/initializers/cloud_storage_initializer.dart';
import 'package:storypad/core/initializers/legacy_storypad_initializer.dart' show LegacyStoryPadInitializer;
import 'package:storypad/core/initializers/licenses_initializer.dart' show LicensesInitializer;
import 'package:storypad/core/initializers/onboarding_initializer.dart' show OnboardingInitializer;
import 'package:storypad/core/initializers/theme_initializer.dart' show ThemeInitializer;
import 'package:storypad/provider_scope.dart' show ProviderScope;
import 'package:storypad/widgets/sp_splash_screen_wrapper.dart';

void main({
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpSplashScreenWrapper.ensureInitialized();

  runApp(
    SpSplashScreenWrapper(
      onLoad: () => _initializeApp(firebaseOptions: firebaseOptions),
      app: const ProviderScope(
        child: App(),
      ),
    ),
  );
}

Future<void> _initializeApp({
  FirebaseOptions? firebaseOptions,
}) async {
  // firebase initialize
  await Firebase.initializeApp(options: firebaseOptions);
  CrashlyticsInitializer.call();
  RemoteConfigInitializer.call();

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
  await CloudStorageInitializer.call();

  LicensesInitializer.call();
}
