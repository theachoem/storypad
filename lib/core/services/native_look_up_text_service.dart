import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/constants/app_constants.dart';

class NativeLookUpTextService {
  static Future<bool> get canLookup async {
    if (Platform.isIOS) return true;
    if (Platform.isAndroid) {
      return await intent('example').canResolveActivity() == true;
    }

    return false;
  }

  static Future<void> Function()? call(String text) {
    if (!kCanNativeLookupText) return null;
    if (Platform.isIOS) {
      return () => SystemChannels.platform.invokeMethod('LookUp.invoke', text);
    } else if (Platform.isAndroid) {
      return () => intent(text).launch();
    }
    return null;
  }

  static AndroidIntent intent(String text) {
    final intent = AndroidIntent(
      action: 'android.intent.action.PROCESS_TEXT',
      type: 'text/plain',
      arguments: {'android.intent.extra.PROCESS_TEXT': text},
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    return intent;
  }
}
