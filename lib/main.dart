import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/app.dart';
import 'package:storypad/core/storages/theme_storage.dart';
import 'package:storypad/initializers/database_initializer.dart';
import 'package:storypad/initializers/device_info_initializer.dart';
import 'package:storypad/initializers/file_initializer.dart';
import 'package:storypad/initializers/firebase_crashlytics_initializer.dart';
import 'package:storypad/initializers/firebase_remote_config_initializer.dart';
import 'package:storypad/initializers/licenses_initializer.dart';
import 'package:storypad/initializers/local_auth_initializer.dart';
import 'package:storypad/initializers/package_info_initializer.dart';
import 'package:storypad/provider_scope.dart';
import 'package:firebase_core/firebase_core.dart';

void main({
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);

  // core
  await EasyLocalization.ensureInitialized();
  await PackageInfoInitializer.call();
  await DeviceInfoInitializer.call();
  await FileInitializer.call();
  await DatabaseInitializer.call();
  await LocalAuthInitializer.call();

  FirebaseCrashlyticsInitializer.call();
  FirebaseRemoteConfigInitializer.call();

  // ui
  await ThemeStorage.instance.load();

  LicensesInitializer.call();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
