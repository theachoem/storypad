import 'package:easy_localization/easy_localization.dart' show EasyLocalization;
import 'package:flutter/material.dart' show WidgetsBinding, WidgetsFlutterBinding, runApp;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:storypad/app.dart' show App;
import 'package:storypad/initializers/app_lock_initializer.dart';
import 'package:storypad/initializers/database_initializer.dart' show DatabaseInitializer;
import 'package:storypad/initializers/device_info_initializer.dart' show DeviceInfoInitializer;
import 'package:storypad/initializers/file_initializer.dart' show FileInitializer;
import 'package:storypad/initializers/firebase_crashlytics_initializer.dart' show FirebaseCrashlyticsInitializer;
import 'package:storypad/initializers/firebase_remote_config_initializer.dart' show FirebaseRemoteConfigInitializer;
import 'package:storypad/initializers/home_initializer.dart';
import 'package:storypad/initializers/licenses_initializer.dart' show LicensesInitializer;
import 'package:storypad/initializers/package_info_initializer.dart' show PackageInfoInitializer;
import 'package:storypad/initializers/theme_initializer.dart' show ThemeInitializer;
import 'package:storypad/provider_scope.dart' show ProviderScope;
import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseOptions;

void main({
  FirebaseOptions? firebaseOptions,
}) async {
  await _showSplashScreen(() async {
    await Firebase.initializeApp(options: firebaseOptions);

    // core
    await EasyLocalization.ensureInitialized();
    await PackageInfoInitializer.call();
    await DeviceInfoInitializer.call();
    await FileInitializer.call();
    await DatabaseInitializer.call();
    await HomeInitializer.call();
    await AppLockInitializer.call();

    FirebaseCrashlyticsInitializer.call();
    FirebaseRemoteConfigInitializer.call();

    // ui
    await ThemeInitializer.call();

    LicensesInitializer.call();
  });

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

Future<void> _showSplashScreen(Future<void> Function() callback) async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await callback();
  FlutterNativeSplash.remove();
}
