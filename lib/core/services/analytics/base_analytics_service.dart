import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/utils/firebase_platform_support.dart';

class BaseAnalyticsService {
  FirebaseAnalytics get firebaseAnalytics => FirebasePlatformSupport.isSupported
      ? FirebaseAnalytics.instance
      : _NoOpFirebaseAnalytics();

  void debug(String logMethod, [Map<String, Object>? printData]) {
    if (printData != null) {
      debugPrint('🎯 $runtimeType#$logMethod -> $printData');
    } else {
      debugPrint('🎯 $runtimeType#$logMethod');
    }
  }
}

class _NoOpFirebaseAnalytics implements FirebaseAnalytics {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
