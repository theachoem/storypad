import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' show EasyLocalization;
import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseOptions;
import 'package:storypad/app.dart' show App;
import 'package:storypad/initializers/app_lock_initializer.dart' show AppLockInitializer;
import 'package:storypad/initializers/backup_initializer.dart' show BackupRepositoryInitializer;
import 'package:storypad/initializers/constants_initializer.dart' show ConstantsInitializer;
import 'package:storypad/initializers/database_initializer.dart' show DatabaseInitializer;
import 'package:storypad/initializers/firebase_crashlytics_initializer.dart' show FirebaseCrashlyticsInitializer;
import 'package:storypad/initializers/firebase_remote_config_initializer.dart' show FirebaseRemoteConfigInitializer;
import 'package:storypad/initializers/firestore_storage_cleanup_initializer.dart';
import 'package:storypad/initializers/legacy_storypad_initializer.dart' show LegacyStoryPadInitializer;
import 'package:storypad/initializers/licenses_initializer.dart' show LicensesInitializer;
import 'package:storypad/initializers/onboarding_initializer.dart' show OnboardingInitializer;
import 'package:storypad/initializers/theme_initializer.dart' show ThemeInitializer;
import 'package:storypad/provider_scope.dart' show ProviderScope;

void main({
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // cleanup
  FirestoreStorageCleanupInitializer.call();

  LicensesInitializer.call();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
