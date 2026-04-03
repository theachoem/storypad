import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'paywall_view.dart';

class PaywallViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PaywallRoute params;

  PaywallViewModel({
    required this.params,
  });
}
