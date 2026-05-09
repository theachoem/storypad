import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/avoid_dublicated_call_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/email_hasher_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/storages/selected_purchase_sync_provider_storage.dart';
import 'package:storypad/core/repositories/backup_repository.dart' show UserChangeType;
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_android_redemption_sheet.dart';

// Uses RevenueCat anonymous ID for purchases. No account login required.
// When a user connects a cloud service (e.g. Google Drive), their globally-unique
// service account ID is used as a RevenueCat identity alias, enabling cross-platform
// purchase sharing. Legacy email-hash users are migrated on initialization.
class InAppPurchaseProvider extends ChangeNotifier with DisposeAwareMixin {
  bool isActive(String productIdentifier) =>
      !kIAPEnabled ? false : _customerInfo?.entitlements.all[productIdentifier]?.isActive == true;

  bool get hasAnyLegacyPurchases => AppLegacyProduct.values.any((product) => isActive(product.productIdentifier));
  bool get periodCalendar => isActive(AppLegacyProduct.period_calendar.productIdentifier);
  bool get isProUser => isActive(AppProduct.storypad_pro_lifetime.productIdentifier) || hasAnyLegacyPurchases;

  CustomerInfo? _customerInfo;
  List<StoreProduct>? storeProducts;
  Offering? offering;

  double? get savingsPercent => offering?.metadata['savings_percent'] != null
      ? double.tryParse(offering?.metadata['savings_percent']?.toString() ?? '')
      : 0;

  StreamSubscription<void>? _userChangesSubscription;

  bool _initialized = false;
  bool get initialized => _initialized;
  final Completer<void> _initializerCompleter = Completer<void>();

  /// The service type ID of the provider currently selected to drive RevenueCat identity.
  /// Defaults to the first connected provider with a valid global ID.
  /// Can be changed explicitly via [setSelectedPurchaseSyncProvider].
  BackupServiceType? _selectedSyncProvider;
  BackupServiceType? get selectedSyncProvider => _selectedSyncProvider;
  final _selectedProviderStorage = SelectedPurchaseSyncProviderStorage();

  final _purchaseGuard = AvoidDublicatedCallService<bool>();

  InAppPurchaseProvider() {
    _initialize().then((_) => _initializerCompleter.complete()).catchError((Object error, StackTrace stackTrace) {
      _initializerCompleter.completeError(error, stackTrace);
    });
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _initializerCompleter.future;
  }

  Future<void> _initialize() async {
    try {
      if (!kIAPEnabled) return;

      await Purchases.setLogLevel(LogLevel.verbose);
      PurchasesConfiguration? configuration;

      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(kRevenueCatAndroidApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(kRevenueCatIosApiKey);
      }

      if (configuration == null) return;
      await Purchases.configure(configuration);

      try {
        _customerInfo = await Purchases.getCustomerInfo();
      } catch (e, s) {
        AppLogger.error('$runtimeType#_initialize error Purchases.getCustomerInfo: $e', stackTrace: s);
      }

      // Load previously persisted provider selection.
      _selectedSyncProvider = await _selectedProviderStorage.readEnum();

      // Check network connectivity before attempting logout/sync
      final hasNetwork = await InternetCheckerService().check();
      if (hasNetwork) {
        // Migrate legacy users who were logged in with email hash.
        bool migrated = await _migrateLegacyUser();

        // BackupProvider.repoInstance is pre-initialized before UI by BackupRepositoryInitializer,
        // so current cloud users are available synchronously here.
        await _syncCloudUserLogins();

        // When recently migrated, also trigger a purchases sync to send store reciepts to RevenueCat
        // to transfer legacy purchases to new user.
        if (migrated) {
          await Purchases.syncPurchases();
          _customerInfo = await Purchases.getCustomerInfo();
        }
      }

      // Listen for real-time customer info updates (cross-device, deferred, etc.)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        notifyListeners();
      });

      // Keep RevenueCat identity in sync whenever cloud service users change.
      _userChangesSubscription = BackupProvider.repoInstance.userChanges.listen((type) {
        _syncCloudUserLogins(changeType: type);
      });
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _syncCloudUserLogins({
    UserChangeType? changeType,
  }) async {
    final services = BackupProvider.repoInstance.services;
    final eligibleServices = services.where((s) => s.serviceType.hasGlobalUserId).toList();

    // Resolve the active service: prefer the user's selection, fall back to first available.
    BackupCloudService? activeService = eligibleServices
        .where((s) => s.serviceType == _selectedSyncProvider)
        .firstOrNull;

    // On first launch (no saved selection) or when the selected provider was removed,
    // auto-select the first available eligible service.
    activeService ??= eligibleServices.firstOrNull;

    if (activeService == null) {
      // No global service connected — revert to anonymous if currently identified.
      _selectedSyncProvider = null;
      await _selectedProviderStorage.remove();

      final appUserId = _customerInfo?.originalAppUserId;
      if (appUserId != null && !appUserId.startsWith('\$RCAnonymousID:')) {
        try {
          _customerInfo = await Purchases.logOut();
          AppLogger.d('$runtimeType#_syncCloudUserLogins logged out, switched to anonymous');
        } catch (e, s) {
          AppLogger.error('$runtimeType#_syncCloudUserLogins logOut error: $e', stackTrace: s);
        }
      }

      notifyListeners();
    } else {
      // Selected provider is gone (signed out) — fall back to first available.
      _selectedSyncProvider = activeService.serviceType;
      await _selectedProviderStorage.writeEnum(_selectedSyncProvider!);

      AppLogger.d(
        '$runtimeType#_syncCloudUserLogins selected provider unavailable, defaulted to "$_selectedSyncProvider"',
      );

      final appUserId = activeService.currentUser?.globalId;
      if (appUserId != null && _customerInfo?.originalAppUserId != appUserId) {
        try {
          final result = await Purchases.logIn(appUserId);
          _customerInfo = result.customerInfo;

          AppLogger.d(
            '$runtimeType#_syncCloudUserLogins logged in as "$appUserId" (new RC user: ${result.created})',
          );
        } catch (e, s) {
          AppLogger.error('$runtimeType#_syncCloudUserLogins logIn("$appUserId") error: $e', stackTrace: s);
        }
      }

      notifyListeners();
    }
  }

  /// Legacy users were logged in with an email hash ID (SHA256 HMAC - 64 char hex).
  /// Detect this and log them out so they use anonymous ID, then sync purchases.
  Future<bool> _migrateLegacyUser() async {
    final appUserId = _customerInfo?.originalAppUserId;
    if (appUserId == null) return false;

    // Anonymous IDs from RevenueCat start with '$RCAnonymousID:'.
    // Legacy email hashes are 64-char hex strings (SHA256 HMAC).
    final isLegacyHash = EmailHasherService.isValidEmailHash(appUserId);
    if (!isLegacyHash) return false;

    AppLogger.d(
      '$runtimeType#_migrateLegacyUser detected legacy email hash user "$appUserId", migrating to anonymous...',
    );

    try {
      await Purchases.logOut();
      AppLogger.d('$runtimeType#_migrateLegacyUser migration complete');
      return true;
    } catch (e, s) {
      AppLogger.error('$runtimeType#_migrateLegacyUser error: $e', stackTrace: s);
      return false;
    }
  }

  /// Updates the selected backup provider used to drive RevenueCat identity and persists the choice.
  /// Pass null to clear the selection (falls back to default on next sync).
  Future<void> setSelectedPurchaseSyncProvider(BackupServiceType? serviceType) async {
    _selectedSyncProvider = serviceType;

    if (serviceType != null) {
      await _selectedProviderStorage.writeEnum(serviceType);
    } else {
      await _selectedProviderStorage.remove();
    }

    await _syncCloudUserLogins();
  }

  StoreProduct? getProduct(String productIdentifier) {
    return storeProducts?.where((storeProduct) => storeProduct.identifier == productIdentifier).firstOrNull;
  }

  ({String? displayPrice, String? displayComparePrice, String? badgeLabel}) getActiveDeal(AppProduct product) {
    final storeProduct = getProduct(product.productIdentifier);
    if (storeProduct == null) return (displayPrice: null, displayComparePrice: null, badgeLabel: null);

    double savingsPercent = this.savingsPercent ?? 0;

    String displayPrice = '${storeProduct.price.toStringAsFixed(2)} ${storeProduct.currencyCode}';
    String? displayComparePrice;

    if (savingsPercent > 0 && savingsPercent < 100) {
      final comparePrice = storeProduct.price / (1 - savingsPercent / 100);
      displayComparePrice = '${comparePrice.toStringAsFixed(2)} ${storeProduct.currencyCode}';
    }

    return (
      displayPrice: displayPrice,
      displayComparePrice: displayComparePrice,
      badgeLabel: displayComparePrice != null ? tr('general.special_offer_for_your_region') : null,
    );
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

      offering = await Purchases.getOfferings().then((e) => e.current);
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

  Future<bool> purchase(BuildContext context) async {
    if (!kIAPEnabled) return false;

    final productToPurchase = AppProduct.storypad_pro_lifetime.productIdentifier;

    return _purchaseGuard.run(() async {
      await _ensureInitialized();

      if (isActive(productToPurchase)) return false;
      if (!context.mounted) return false;

      bool success = false;

      await MessengerService.of(context).showLoading(
        debugSource: '$runtimeType#purchase',
        future: () async {
          // Use cached product if available, otherwise fetch.
          StoreProduct? storeProduct = getProduct(productToPurchase);

          storeProduct ??= await Purchases.getProducts(
            [productToPurchase],
            productCategory: ProductCategory.nonSubscription,
          ).then((e) => e.firstOrNull);

          if (storeProduct == null) return;

          try {
            PurchaseResult result = await Purchases.purchase(PurchaseParams.storeProduct(storeProduct));
            _customerInfo = result.customerInfo;
            if (isActive(productToPurchase)) success = true;
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
          await Purchases.syncPurchases();
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
    if (!kIAPEnabled) return;

    if (Platform.isIOS) {
      await _ensureInitialized();
      await Purchases.presentCodeRedemptionSheet();
      if (context.mounted) await restorePurchase(context);
    } else if (Platform.isAndroid) {
      SpAndroidRedemptionSheet().show(context: context);
    }
  }

  @override
  void dispose() {
    _userChangesSubscription?.cancel();
    super.dispose();
  }
}
