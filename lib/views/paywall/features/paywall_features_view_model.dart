import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/paywall_feature_object.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'paywall_features_view.dart';

class PaywallFeaturesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PaywallFeaturesRoute params;

  PaywallFeaturesViewModel({
    required this.params,
  }) {
    preloadUrls();
  }

  late final PageController pageController = PageController(initialPage: params.initialPage);

  void preloadUrls() {
    // getDownloadUrl already handle completer to prevent duplicate download for same urlPath
    // So UI, can call getDownloadURL again to get this preloaded completer.
    for (var feature in params.features) {
      for (String urlPath in feature.demoImages) {
        CloudStorageService.instance.getDownloadURL(urlPath);
      }
    }
  }

  Future<List<String>> fetchDemoImageUrlsFor(PaywallFeatureObject feature) async {
    List<String> urls = [];

    for (String urlPath in feature.demoImages) {
      String? imageUrl = await CloudStorageService.instance.getDownloadURL(urlPath);
      if (imageUrl != null) urls.add(imageUrl);
    }

    return urls;
  }

  void purchase(BuildContext context) async {
    await context.read<InAppPurchaseProvider>().purchase(context);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
