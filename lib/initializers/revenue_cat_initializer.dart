import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/constants/app_constants.dart';

class RevenueCatInitializer {
  static const entitlementsId = 'Pro';

  static Future<void> call() async {
    await Purchases.setLogLevel(LogLevel.verbose);
    PurchasesConfiguration? configuration;

    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(kRevenueCatAndroidApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(kRevenueCatIosApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }
}
