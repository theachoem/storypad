import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';

class FirebaseInitializer {
  static const _timeout = Duration(seconds: 7);

  /// Never throws and never blocks startup beyond [_timeout], even if
  /// Firebase/Google domains are unreachable on the user's network. Sets
  /// [kFirebaseAvailable] so downstream adaptors can fall back gracefully.
  static Future<void> call({FirebaseOptions? options}) async {
    if (Platform.isLinux) return;

    try {
      await Firebase.initializeApp(options: options).timeout(_timeout);
      kFirebaseAvailable = true;
    } catch (error) {
      kFirebaseAvailable = false;
      debugPrint('FirebaseInitializer: Firebase.initializeApp() failed or timed out: $error');
    }
  }
}
