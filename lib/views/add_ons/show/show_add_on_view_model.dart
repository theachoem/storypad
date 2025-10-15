import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'show_add_on_view.dart';

class ShowAddOnViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowAddOnRoute params;

  ShowAddOnViewModel({
    required this.params,
  }) {
    load();
  }

  List<String>? demoImageUrls;

  void load() async {
    for (String urlPath in params.addOn.demoImages) {
      String? imageUrl = await FirestoreStorageService.instance.getDownloadURL(urlPath);
      demoImageUrls ??= [];

      if (imageUrl != null) demoImageUrls?.add(imageUrl);
      notifyListeners();
    }
  }

  void purchase(BuildContext context, String productIdentifier) async {
    await context.read<InAppPurchaseProvider>().purchase(
      context,
      productIdentifier,
      params.addOn.onPurchased!,
    );
  }
}
