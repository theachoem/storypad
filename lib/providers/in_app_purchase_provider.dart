import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/avoid_dublicated_call_service.dart';
import 'package:storypad/core/services/email_hasher_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/app_product.dart';

// Uses RevenueCat anonymous ID for purchases. No account login required.
// Legacy users who were logged in with email hash are migrated on initialization.
class InAppPurchaseProvider extends ChangeNotifier with DisposeAwareMixin {
  bool isActive(String productIdentifier) => _customerInfo?.entitlements.all[productIdentifier]?.isActive == true;

  bool get hasAnyLegacyPurchases => AppLegacyProduct.values.any((product) => isActive(product.productIdentifier));
  bool get isProUser => isActive(AppProduct.pro.productIdentifier) || hasAnyLegacyPurchases;

  CustomerInfo? _customerInfo;
  List<StoreProduct>? storeProducts;

  bool _initialized = false;
  bool get initialized => _initialized;
  Completer<void>? _initCompleter;

  final _purchaseGuard = AvoidDublicatedCallService<bool>();

  InAppPurchaseProvider() {
    _initCompleter = Completer<void>();
    _initialize()
        .then((_) {
          _initCompleter?.complete();
        })
        .catchError((Object error, StackTrace stackTrace) {
          _initCompleter?.completeError(error, stackTrace);
        });
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _initCompleter?.future;
  }

  Future<void> _initialize() async {
    try {
      if (kIAPEnabled) {
        await Purchases.setLogLevel(LogLevel.verbose);
        PurchasesConfiguration? configuration;

        if (Platform.isAndroid) {
          configuration = PurchasesConfiguration(kRevenueCatAndroidApiKey);
        } else if (Platform.isIOS) {
          configuration = PurchasesConfiguration(kRevenueCatIosApiKey);
        }

        if (configuration != null) {
          await Purchases.configure(configuration);

          // Listen for real-time customer info updates (cross-device, deferred, etc.)
          Purchases.addCustomerInfoUpdateListener((customerInfo) {
            _customerInfo = customerInfo;
            notifyListeners();
          });

          try {
            _customerInfo = await Purchases.getCustomerInfo();
          } catch (e, s) {
            AppLogger.error('$runtimeType#_initialize error Purchases.getCustomerInfo: $e', stackTrace: s);
          }

          // Migrate legacy users who were logged in with email hash.
          await _migrateLegacyUser();
        }
      }
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Legacy users were logged in with an email hash ID (SHA256 HMAC - 64 char hex).
  /// Detect this and log them out so they use anonymous ID, then sync purchases.
  Future<void> _migrateLegacyUser() async {
    final appUserId = _customerInfo?.originalAppUserId;
    if (appUserId == null) return;

    // Check network connectivity before attempting logout/sync
    final hasNetwork = await InternetCheckerService().check();
    if (!hasNetwork) {
      AppLogger.d('$runtimeType#_migrateLegacyUser skipping migration (no network) - will retry on next launch');
      return;
    }

    // Anonymous IDs from RevenueCat start with '$RCAnonymousID:'.
    // Legacy email hashes are 64-char hex strings (SHA256 HMAC).
    final isLegacyHash = EmailHasherService.isValidEmailHash(appUserId);
    if (!isLegacyHash) return;

    AppLogger.d(
      '$runtimeType#_migrateLegacyUser detected legacy email hash user "$appUserId", migrating to anonymous...',
    );

    try {
      await Purchases.logOut();
      await Purchases.syncPurchases();

      // Fetch fresh customer info after logout and sync
      _customerInfo = await Purchases.getCustomerInfo();

      AppLogger.d('$runtimeType#_migrateLegacyUser migration complete');
    } catch (e, s) {
      AppLogger.error('$runtimeType#_migrateLegacyUser error: $e', stackTrace: s);
    }
  }

  StoreProduct? getProduct(String productIdentifier) {
    return storeProducts?.where((storeProduct) => storeProduct.identifier == productIdentifier).firstOrNull;
  }

  Future<List<StoreProduct>?> fetchAndCacheProducts({
    required String debugSource,
  }) async {
    if (!kIAPEnabled) return null;

    try {
      storeProducts = await Purchases.getProducts(
        AppProduct.productIdentifiers,
        productCategory: ProductCategory.nonSubscription,
      );
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

  Future<bool> purchase(
    BuildContext context,
    String productIdentifier,
    Future<void> Function()? onPurchased,
  ) async {
    if (!kIAPEnabled) return false;

    return _purchaseGuard.run(() async {
      await _ensureInitialized();

      if (isActive(productIdentifier)) return false;
      if (!context.mounted) return false;

      bool success = false;

      await MessengerService.of(context).showLoading(
        debugSource: '$runtimeType#purchase',
        future: () async {
          // Use cached product if available, otherwise fetch.
          StoreProduct? storeProduct = getProduct(productIdentifier);
          storeProduct ??= await Purchases.getProducts(
            [productIdentifier],
            productCategory: ProductCategory.nonSubscription,
          ).then((e) => e.firstOrNull);

          if (storeProduct == null) return;

          try {
            PurchaseResult result = await Purchases.purchase(PurchaseParams.storeProduct(storeProduct));
            _customerInfo = result.customerInfo;
            if (isActive(productIdentifier)) {
              await onPurchased?.call();
              success = true;
            }
            notifyListeners();
          } on PlatformException catch (e, s) {
            PurchasesErrorCode errorCode = PurchasesErrorHelper.getErrorCode(e);
            if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
              AppLogger.error('$runtimeType#purchase error: $errorCode', stackTrace: s);
              if (context.mounted) await MessengerService.of(context).showError();
            }
          }
        },
      );

      if (success && context.mounted) {
        await MessengerService.of(context).showSuccess();
      }

      return success;
    });
  }

  Future<void> restorePurchase(BuildContext context) async {
    if (!kIAPEnabled) return;

    await _ensureInitialized();
    if (!context.mounted) return;

    bool restored = false;

    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#restorePurchase',
      future: () async {
        try {
          _customerInfo = await Purchases.restorePurchases();
          notifyListeners();
          restored = true;
        } catch (e, s) {
          String? errorMessage;

          if (e is PlatformException) {
            PurchasesErrorCode errorCode = PurchasesErrorHelper.getErrorCode(e);
            errorMessage = 'Error restoring purchases: $errorCode';
          }

          AppLogger.error('$runtimeType#restorePurchase error: $e', stackTrace: s);
          if (context.mounted) await MessengerService.of(context).showError(errorMessage);
        }
      },
    );

    if (restored && isProUser && context.mounted) await MessengerService.of(context).showSuccess();
  }

  Future<void> presentCodeRedemptionSheet(BuildContext context) async {
    if (!kIAPEnabled || !Platform.isIOS) return;

    await _ensureInitialized();
    await Purchases.presentCodeRedemptionSheet();
    if (context.mounted) await restorePurchase(context);
  }
}
