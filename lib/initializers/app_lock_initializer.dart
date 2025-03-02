// ignore_for_file: library_private_types_in_public_api

import 'package:storypad/core/objects/app_lock_object.dart';
import 'package:storypad/core/services/local_auth_service.dart';
import 'package:storypad/core/storages/app_lock_storage.dart';

class _AppLockInitialData {
  final LocalAuthService localAuth;
  final AppLockObject appLock;

  _AppLockInitialData({
    required this.localAuth,
    required this.appLock,
  });
}

class AppLockInitializer {
  static _AppLockInitialData? _initialData;

  static Future<void> call() async {
    final localAuth = LocalAuthService();
    await localAuth.load();
    final appLock = await AppLockStorage().readObject() ?? AppLockObject.init();

    _initialData = _AppLockInitialData(
      localAuth: localAuth,
      appLock: appLock,
    );
  }

  static _AppLockInitialData? getAndClear() {
    final tmp = _initialData;
    _initialData = null;
    return tmp;
  }
}
