import 'dart:io';

class FirebasePlatformSupport {
  const FirebasePlatformSupport._();

  static bool get isSupported => !Platform.isLinux;
}
