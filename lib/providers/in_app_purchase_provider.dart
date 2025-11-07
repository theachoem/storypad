import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/email_hasher_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_connect_with_google_drive_sheet.dart';

// This provider securely manages in-app purchases across platforms without storing your actual email.
// It authenticates using your Google account via SSO, then immediately hashes your email locally.
// Only this hashed identifier is stored in RevenueCat and Firebase - your real email never leaves your device.
// This design ensures strong privacy protection while enabling purchase restoration and cross-device support.
class InAppPurchaseProvider extends ChangeNotifier {
  bool isActive(String productIdentifier) =>
      _rewardAddOns?.contains(productIdentifier) == true ||
      _customerInfo?.entitlements.all[productIdentifier]?.isActive == true;

  bool get voiceJournal => isActive(AppProduct.voice_journal.productIdentifier);
  bool get relaxSound => isActive(AppProduct.relax_sounds.productIdentifier);
  bool get template => isActive(AppProduct.templates.productIdentifier);
  bool get periodCalendar => isActive(AppProduct.period_calendar.productIdentifier);

  DateTime? _rewardExpiredAt;
  List<String>? _rewardAddOns;

  DateTime? get rewardExpiredAt => _rewardExpiredAt;
  List<String> get rewardAddOns => _rewardAddOns ?? [];

  CustomerInfo? _customerInfo;
  List<StoreProduct>? storeProducts;

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

  StoreProduct? getProduct(String productIdentifier) {
    return storeProducts?.where((storeProduct) => storeProduct.identifier == productIdentifier).firstOrNull;
  }

  Future<List<StoreProduct>?> fetchAndCacheProducts({
    required String debugSource,
  }) async {
    try {
      storeProducts = kIAPEnabled
          ? await Purchases.getProducts(AppProduct.productIdentifiers, productCategory: ProductCategory.nonSubscription)
          : [];
    } on PlatformException catch (e, s) {
      AppLogger.error(
        '$runtimeType#fetchProducts($debugSource) PlatformException - code: ${e.code}, message: ${e.message}, details: ${e.details}',
        stackTrace: s,
      );
    } catch (e, s) {
      AppLogger.error('$runtimeType#fetchProducts($debugSource) error: ${e.toString()}', stackTrace: s);
    }

    return storeProducts;
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
      } catch (e, s) {
        AppLogger.error('$runtimeType#revalidateCustomerInfo error Purchases.login: $e', stackTrace: s);
      }
    }

    notifyListeners();
  }

  Future<bool> purchase(
    BuildContext context,
    String productIdentifier,
    Future<void> Function()? onPurchased,
  ) async {
    if (!kIAPEnabled) return false;

    await _loginIfNot(context);

    if (_customerInfo == null) return false;
    if (isActive(productIdentifier)) return false;
    if (!context.mounted) return false;

    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#_loginIfNot',
      future: () async {
        StoreProduct? storeProduct = await Purchases.getProducts(
          [productIdentifier],
          productCategory: ProductCategory.nonSubscription,
        ).then((e) => e.firstOrNull);

        if (storeProduct != null) {
          try {
            PurchaseResult result = await Purchases.purchase(PurchaseParams.storeProduct(storeProduct));
            _customerInfo = result.customerInfo;
            if (isActive(productIdentifier)) await onPurchased?.call();
            notifyListeners();
          } on PlatformException catch (e, s) {
            PurchasesErrorCode errorCode = PurchasesErrorHelper.getErrorCode(e);
            AppLogger.error('$runtimeType#purchase error: $errorCode', stackTrace: s);
          }
        }
      },
    );

    if (isActive(productIdentifier)) {
      if (context.mounted) await MessengerService.of(context).showSuccess();
      return true;
    }

    return false;
  }

  // Restore purchase handle like a refresh.
  // Make sure data is valid & _customerInfo is latest.
  Future<void> restorePurchase(
    BuildContext context,
  ) async {
    if (!kIAPEnabled) return;

    await _logoutIfInvalid(context);
    if (!context.mounted) return;
    await _loginIfNot(context);

    if (!context.mounted) return;
    GoogleUserObject? currentUser = context.read<BackupProvider>().currentUser;
    if (currentUser == null) return;

    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      notifyListeners();
    } catch (e, s) {
      AppLogger.error('$runtimeType#restorePurchase error Purchases.restorePurchases: $e', stackTrace: s);
    }
  }

  Future<void> _loginIfNot(BuildContext context) async {
    if (!kIAPEnabled) return;
    if (_customerInfo != null) return;

    GoogleUserObject? currentUser = context.read<BackupProvider>().currentUser;
    if (currentUser == null) {
      await SpConnectWithGoogleDriveSheet().show(context: context);
      if (context.mounted) currentUser = context.read<BackupProvider>().currentUser;
    }

    if (currentUser != null && context.mounted) {
      String hash = EmailHasherService(secretKey: kEmailHasherSecreyKey).hmacEmail(currentUser.email);

      MessengerService.of(context).showLoading(
        debugSource: '$runtimeType#_loginIfNot',
        future: () async {
          try {
            LogInResult loginResult = await Purchases.logIn(hash);
            _customerInfo = loginResult.customerInfo;
            notifyListeners();
          } catch (e, s) {
            AppLogger.error('$runtimeType#purchase error Purchases.login: $e', stackTrace: s);
          }
        },
      );
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

  Future<void> presentCodeRedemptionSheet(BuildContext context) async {
    if (kIAPEnabled && Platform.isIOS) {
      await Purchases.presentCodeRedemptionSheet();
      if (context.mounted) restorePurchase(context);
    }
  }
}
