import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/add_on_object.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'add_ons_view.dart';

class AddOnsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final AddOnsRoute params;

  AddOnsViewModel({
    required this.params,
  }) {
    load();
  }

  List<AddOnObject>? addOns;
  List<StoreProduct>? storeProducts;
  String? errorMessage;

  StoreProduct? getProduct(String productIdentifier) {
    return storeProducts?.where((storeProduct) => storeProduct.identifier == productIdentifier).firstOrNull;
  }

  Future<void> load() async {
    errorMessage = null;

    try {
      storeProducts = await Purchases.getProducts(
        AppProduct.productIdentifiers,
        productCategory: ProductCategory.nonSubscription,
      );
    } on PlatformException catch (e) {
      errorMessage = e.message;
      debugPrint('$runtimeType#load error: $errorMessage');
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('$runtimeType#load error: $errorMessage');
    }

    addOns = [
      AddOnObject(
        type: AppProduct.templates,
        title: tr('add_ons.templates.title'),
        subtitle: tr('add_ons.templates.subtitle'),
        displayPrice: getProduct('templates')?.priceString,
        iconData: SpIcons.lightBulb,
        weekdayColor: 2,
        demoImages: [
          '/add_ons_demos/templates/1.png',
          '/add_ons_demos/templates/2.png',
          '/add_ons_demos/templates/3.png',
          '/add_ons_demos/templates/4.png',
        ],
        onTry: null,
        onOpen: (BuildContext context) => const TemplatesRoute().push(context, rootNavigator: true),
      ),
      AddOnObject(
        type: AppProduct.relax_sounds,
        title: tr('add_ons.relax_sounds.title'),
        subtitle: tr('add_ons.relax_sounds.subtitle'),
        displayPrice: getProduct('relax_sounds')?.priceString,
        iconData: SpIcons.musicNote,
        weekdayColor: 1,
        demoImages: [
          '/add_ons_demos/relax_sounds/1.png',
          '/add_ons_demos/relax_sounds/2.png',
          '/add_ons_demos/relax_sounds/3.png',
          '/add_ons_demos/relax_sounds/4.png',
        ],
        onTry: null,
        onOpen: (BuildContext context) => const RelaxSoundsRoute().push(context, rootNavigator: true),
      ),
    ];

    notifyListeners();
  }

  Future<void> restorePurchase(BuildContext context) async {
    return MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#restorePurchase',
      future: () => context.read<InAppPurchaseProvider>().restorePurchase(context),
    );
  }
}
