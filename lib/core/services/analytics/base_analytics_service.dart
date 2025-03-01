import 'package:flutter/material.dart';

class BaseAnalyticsService {
  void debug(String logMethod, [Map<String, Object>? printData]) {
    if (printData != null) {
      debugPrint('🎯 $runtimeType#$logMethod -> $printData');
    } else {
      debugPrint('🎯 $runtimeType#$logMethod');
    }
  }
}
