import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'paywall_features_view.dart';

class PaywallFeaturesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PaywallFeaturesRoute params;

  PaywallFeaturesViewModel({
    required this.params,
  }) {
    preloadFiles();
  }

  late final PageController pageController = PageController(initialPage: params.initialPage);

  void preloadFiles() {
    // downloadFile deduplicates requests using completers, so calling this
    // from multiple screens is safe and helps images be ready sooner.
    for (var feature in params.features) {
      for (String urlPath in feature.demoImagePaths) {
        CloudStorageService.instance.downloadFile(urlPath);
      }
    }
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
