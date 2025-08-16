import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/email_hasher_service.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/backup_provider.dart';

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
      await revalidateCustomerInfo(context);
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

  Future<void> revalidateCustomerInfo(BuildContext context) async {
    if (!kIAPEnabled) return;

    await _logoutIfInvalid(context);
    if (!context.mounted) return;

    GoogleUserObject? currentUser = context.read<BackupProvider>().currentUser;
    if (currentUser != null) {
      String hash = EmailHasherService(secretKey: kEmailHasherSecreyKey).hmacEmail(currentUser.email);
      if (_customerInfo?.originalAppUserId == hash) return;

      try {
        LogInResult result = await Purchases.logIn(hash);
        _customerInfo = result.customerInfo;
        notifyListeners();
      } catch (e) {
        debugPrint('$runtimeType#revalidateCustomerInfo error Purchases.login: $e');
      }
    }
  }

  Future<void> purchase(
    BuildContext context,
    String productIdentifier,
  ) async {
    if (!kIAPEnabled) return;

    await _loginIfNot(context);

    if (_customerInfo == null) return;
    if (isActive(productIdentifier)) return;

    StoreProduct? storeProduct = await Purchases.getProducts(
      [productIdentifier],
      productCategory: ProductCategory.nonSubscription,
    ).then((e) => e.firstOrNull);

    if (storeProduct != null) {
      try {
        PurchaseResult result = await Purchases.purchaseStoreProduct(storeProduct);
        _customerInfo = result.customerInfo;
        notifyListeners();
      } on PlatformException catch (e) {
        PurchasesErrorCode errorCode = PurchasesErrorHelper.getErrorCode(e);
        debugPrint('$runtimeType#purchase error: $errorCode');
      }
    }
  }

  // Restore purchase handle like a refresh.
  // Make sure data is valid & _customerInfo is latest.
  Future<void> restorePurchase(
    BuildContext context,
  ) async {
    if (!kIAPEnabled) return;

    await _logoutIfInvalid(context);
    if (!context.mounted) return;
    return _loginIfNot(context);
  }

  Future<void> _loginIfNot(BuildContext context) async {
    if (!kIAPEnabled) return;
    if (_customerInfo != null) return;

    GoogleUserObject? currentUser = context.read<BackupProvider>().currentUser;
    if (currentUser == null) {
      await context.read<BackupProvider>().signIn(context);
      if (context.mounted) currentUser = context.read<BackupProvider>().currentUser;
    }

    if (currentUser != null) {
      String hash = EmailHasherService(secretKey: kEmailHasherSecreyKey).hmacEmail(currentUser.email);

      try {
        LogInResult loginResult = await Purchases.logIn(hash);
        _customerInfo = loginResult.customerInfo;
        notifyListeners();
      } catch (e) {
        debugPrint('$runtimeType#purchase error Purchases.login: $e');
      }
    }
  }

  Future<void> _logoutIfInvalid(BuildContext context) async {
    if (!kIAPEnabled) return;
    GoogleUserObject? currentUser = context.read<BackupProvider>().currentUser;

    if (currentUser != null && _customerInfo != null) {
      String hash = EmailHasherService(secretKey: kEmailHasherSecreyKey).hmacEmail(currentUser.email);

      if (_customerInfo?.originalAppUserId != hash) {
        await Purchases.logOut();
        _customerInfo = null;
        notifyListeners();
      }
    } else if (currentUser == null && _customerInfo != null) {
      await Purchases.logOut();
      _customerInfo = null;
      notifyListeners();
    }
  }
}
