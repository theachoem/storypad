import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'paywalls_view.dart';

class PaywallsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PaywallsRoute params;

  PaywallsViewModel({
    required this.params,
  }) {
    load();
  }

  Offerings? offerings;
  String? errorMessage;

  Future<void> load() async {
    try {
      offerings = await Purchases.getOfferings();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('$runtimeType#load error: $e');
    }

    notifyListeners();
  }
}
