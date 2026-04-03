import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/paywall_feature_object.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'paywall_features_view.dart';

class PaywallFeaturesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PaywallFeaturesRoute params;

  PaywallFeaturesViewModel({
    required this.params,
  });

  late final PageController pageController = PageController(initialPage: params.initialPage);

  Map<PaywallFeature, Completer<List<String>>> demoImageUrls = {};

  void load() {
    for (var feature in params.features) {
      fetchDemoImageUrlsFor(feature);
    }
  }

  Future<List<String>> fetchDemoImageUrlsFor(PaywallFeatureObject feature) async {
    if (demoImageUrls[feature.type] != null) return demoImageUrls[feature.type]!.future;
    demoImageUrls[feature.type] = Completer<List<String>>();

    List<String> urls = [];
    for (String urlPath in feature.demoImages) {
      String? imageUrl = await FirestoreStorageService.instance.getDownloadURL(urlPath);
      if (imageUrl != null) urls.add(imageUrl);
    }

    demoImageUrls[feature.type]?.complete(urls);
    return demoImageUrls[feature.type]!.future;
  }

  void purchase(BuildContext context) async {
    await context.read<InAppPurchaseProvider>().purchase(
      context,
      AppProduct.pro.productIdentifier,
      params.features.elementAt(pageController.page?.round() ?? 0).onPurchased,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
