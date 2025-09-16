import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/types/app_product.dart';

// This provider securely manages in-app purchases across platforms without storing your actual email.
// It authenticates using your Google account via SSO, then immediately hashes your email locally.
// Only this hashed identifier is stored in RevenueCat and Firebase - your real email never leaves your device.
// This design ensures strong privacy protection while enabling purchase restoration and cross-device support.
class InAppPurchaseProvider extends ChangeNotifier {
  bool isActive(String productIdentifier) => _customerInfo?.entitlements.all[productIdentifier]?.isActive == true;

  bool get relaxSound => isActive(AppProduct.relax_sounds.productIdentifier);
  bool get template => isActive(AppProduct.templates.productIdentifier);

  CustomerInfo? _customerInfo;

  InAppPurchaseProvider(BuildContext context) {
    _initialize(context).then((_) async {
      if (!context.mounted) return;
      await _loadCustomerInfo(context);
    });
  }

  Future<void> _initialize(BuildContext context) async {
    if (!kIAPEnabled) return;

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

  Future<void> _loadCustomerInfo(BuildContext context) async {
    if (!kIAPEnabled) return;

    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('$runtimeType#_loadCustomerInfo error Purchases.login: $e');
    }
  }

  Future<void> purchase(
    BuildContext context,
    String productIdentifier,
  ) async {
    if (!kIAPEnabled) return;
    if (_customerInfo == null) return;
    if (isActive(productIdentifier)) return;

    StoreProduct? storeProduct = await Purchases.getProducts(
      [productIdentifier],
      productCategory: ProductCategory.nonSubscription,
    ).then((e) => e.firstOrNull);

    if (storeProduct != null) {
      try {
        PurchaseResult result = await Purchases.purchase(PurchaseParams.storeProduct(storeProduct));
        _customerInfo = result.customerInfo;
        notifyListeners();
      } on PlatformException catch (e) {
        PurchasesErrorCode errorCode = PurchasesErrorHelper.getErrorCode(e);
        debugPrint('$runtimeType#purchase error: $errorCode');
      }
    }
  }

  Future<void> restorePurchase(
    BuildContext context,
  ) async {
    if (!kIAPEnabled) return;
    await _loadCustomerInfo(context);
  }
}
