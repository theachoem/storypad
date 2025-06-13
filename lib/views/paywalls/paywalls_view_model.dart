import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/storages/premium_interested_plans_storage.dart';
import 'paywalls_view.dart';

class PaywallsOffering {
  final String name;
  final String? badge;
  final String baseDisplayPrice;
  final String? compareAtPrice;
  final String helperText;

  bool interested;

  PaywallsOffering({
    required this.name,
    required this.badge,
    required this.baseDisplayPrice,
    required this.compareAtPrice,
    required this.helperText,
    this.interested = false,
  });
}

class PaywallsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PaywallsRoute params;

  PaywallsViewModel({
    required this.params,
  }) {
    load();
  }

  int selectedOfferIndex = 0;

  void setSelectOfferIndex(int index) {
    selectedOfferIndex = index;
    notifyListeners();
  }

  List<PaywallsOffering>? offers;

  Offerings? offerings;
  String? errorMessage;

  Future<void> load() async {
    try {
      offerings = await Purchases.getOfferings();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('$runtimeType#load error: $e');
    }

    Map<String, dynamic> interestedPlans = await PremiumInterestedPlansStorage().readMap() ?? {};

    var monthly = offerings?.getOffering('default')?.monthly;
    var yearly = offerings?.getOffering('default')?.annual;
    var lifetime = offerings?.getOffering('default')?.lifetime;

    var yearlyPrice = yearly?.storeProduct.price;
    var monthlyPrice = monthly?.storeProduct.price;
    var lifetimePrice = lifetime?.storeProduct.price;

    offers = [
      PaywallsOffering(
        name: 'Monthly',
        badge: null,
        baseDisplayPrice: monthlyPrice != null ? "$monthlyPrice ${monthly?.storeProduct.currencyCode}" : 'N/A',
        compareAtPrice: null,
        helperText: 'Monthly is like buying a coffee to try - taste different flavors and see what you like.',
        interested: interestedPlans['Monthly'] != null,
      ),
      PaywallsOffering(
        name: 'Yearly',
        badge: yearlyPrice != null
            ? "${(yearlyPrice / 12).toStringAsFixed(2)} ${yearly?.storeProduct.currencyCode}"
            : null,
        baseDisplayPrice: yearlyPrice != null ? "$yearlyPrice ${yearly?.storeProduct.currencyCode}" : 'N/A',
        compareAtPrice: null,
        helperText:
            'Yearly is for those who love the flavor, want full access to our café, and help us grow into an even more beautiful place each year.',
        interested: interestedPlans['Yearly'] != null,
      ),
      PaywallsOffering(
        name: 'Lifetime',
        badge: null,
        baseDisplayPrice: lifetimePrice != null ? "$lifetimePrice ${lifetime?.storeProduct.currencyCode}" : 'N/A',
        compareAtPrice: null,
        helperText:
            'Lifetime is like buying the café and chilling here forever with free Wi-Fi - no more bills, just endless access!',
        interested: interestedPlans['Lifetime'] != null,
      ),
    ];

    notifyListeners();
  }

  void markAsInterested() async {
    await PremiumInterestedPlansStorage().toggleInterested(offers![selectedOfferIndex].name);
    await load();

    Map<String, dynamic>? newResult = await PremiumInterestedPlansStorage().readMap();
    if (newResult != null) FirebaseFirestore.instance.collection('plan_interests').doc(kDeviceInfo.id).set(newResult);
  }
}
