import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/storages/previously_visited_template_tab.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'templates_view.dart';

class TemplatesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TemplatesRoute params;

  late int initialTabIndex;
  final ValueNotifier<List<IconButton>?> appBarActionsNotifier = ValueNotifier(null);

  TemplatesViewModel({
    required this.params,
    required BuildContext context,
  }) {
    bool isProUser = context.read<InAppPurchaseProvider>().isProUser;
    int? currentIndex = PreviouslyVisitedTemplateTabIndexStorage.appInstance.currentIndex;
    if (!isProUser) currentIndex = null;
    initialTabIndex = currentIndex ?? 1;
  }

  void setCurrentIndex(int index) {
    PreviouslyVisitedTemplateTabIndexStorage.appInstance.write(index);
  }

  @override
  void dispose() {
    appBarActionsNotifier.dispose();
    super.dispose();
  }
}
