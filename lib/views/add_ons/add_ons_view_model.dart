import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/add_on_object.dart';
import 'package:storypad/core/objects/calendar_segment_id.dart';
import 'package:storypad/core/objects/product_deal_object.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_calendar_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'add_ons_view.dart';

class AddOnsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final AddOnsRoute params;
  final BuildContext context;

  AddOnsViewModel({
    required this.params,
    required this.context,
  }) {
    load(context).then((_) {
      if (context.mounted) params.onLoaded?.call(context, this);
    });
  }

  List<AddOnObject>? addOns;
  Map<AppProduct, ProductDealObject> activeDeals = ProductDealObject.getActiveDeals();

  DateTime? get dealEndDate =>
      activeDeals.values.map((deal) => deal.endDate).fold<DateTime?>(null, (previousValue, element) {
        if (previousValue == null) return element;
        return previousValue.isBefore(element) ? previousValue : element;
      });

  StoreProduct? getProduct(String productIdentifier) =>
      context.read<InAppPurchaseProvider>().getProduct(productIdentifier);

  ({String? displayPrice, String? displayComparePrice, String? badgeLabel}) getActiveDeal(AppProduct product) {
    final storeProduct = getProduct(product.productIdentifier);
    if (storeProduct == null) return (displayPrice: null, displayComparePrice: null, badgeLabel: null);

    final prices = activeDeals[product]?.getDisplayPrice(storeProduct);
    if (prices != null) {
      return (
        displayPrice: prices.displayPrice,
        displayComparePrice: prices.displayComparePrice,
        badgeLabel: '${activeDeals[product]!.discountPercentage}% OFF',
      );
    } else {
      return (
        displayPrice: storeProduct.priceString,
        displayComparePrice: null,
        badgeLabel: null,
      );
    }
  }

  Future<void> load(BuildContext context) async {
    await context.read<InAppPurchaseProvider>().fetchAndCacheProducts(debugSource: '$runtimeType#load');

    addOns = [
      AddOnObject(
        type: AppProduct.voice_journal,
        title: tr('add_ons.voice_journal.title'),
        subtitle: tr('add_ons.voice_journal.subtitle'),
        displayPrice: getActiveDeal(AppProduct.voice_journal).displayPrice,
        displayComparePrice: getActiveDeal(AppProduct.voice_journal).displayComparePrice,
        badgeLabel: getActiveDeal(AppProduct.voice_journal).badgeLabel,
        iconData: SpIcons.voice,
        weekdayColor: 5,
        demoImages: [
          '/add_ons_demos/voice_journal/voice_journal_1.jpg',
          '/add_ons_demos/voice_journal/voice_journal_2.jpg',
          '/add_ons_demos/voice_journal/voice_journal_3.jpg',
        ],
        onTry: null,
        onPurchased: null,
        onOpen: (BuildContext context) => LibraryRoute(
          initialTabIndex: 1,
        ).push(context, rootNavigator: true),
      ),
      AddOnObject(
        type: AppProduct.templates,
        title: tr('add_ons.templates.title'),
        subtitle: tr('add_ons.templates.subtitle'),
        displayPrice: getActiveDeal(AppProduct.templates).displayPrice,
        displayComparePrice: getActiveDeal(AppProduct.templates).displayComparePrice,
        badgeLabel: getActiveDeal(AppProduct.templates).badgeLabel,
        iconData: SpIcons.lightBulb,
        weekdayColor: 2,
        demoImages: [
          '/add_ons_demos/templates/template_1.jpg',
          '/add_ons_demos/templates/template_2.jpg',
          '/add_ons_demos/templates/template_3.jpg',
          '/add_ons_demos/templates/template_4.jpg',
        ],
        onTry: null,
        onPurchased: null,
        onOpen: (BuildContext context) => const TemplatesRoute().push(context, rootNavigator: true),
      ),
      AddOnObject(
        type: AppProduct.relax_sounds,
        title: tr('add_ons.relax_sounds.title'),
        subtitle: tr('add_ons.relax_sounds.subtitle'),
        displayPrice: getActiveDeal(AppProduct.relax_sounds).displayPrice,
        displayComparePrice: getActiveDeal(AppProduct.relax_sounds).displayComparePrice,
        badgeLabel: getActiveDeal(AppProduct.relax_sounds).badgeLabel,
        iconData: SpIcons.musicNote,
        weekdayColor: 1,
        demoImages: [
          '/add_ons_demos/relax_sounds/relax_sound_1.jpg',
          '/add_ons_demos/relax_sounds/relax_sound_2.jpg',
          '/add_ons_demos/relax_sounds/relax_sound_3.jpg',
          '/add_ons_demos/relax_sounds/relax_sound_4.jpg',
        ],
        onTry: null,
        onPurchased: null,
        onOpen: (BuildContext context) => const RelaxSoundsRoute().push(context, rootNavigator: true),
      ),
      AddOnObject(
        type: AppProduct.period_calendar,
        title: tr('add_ons.period_calendar.title'),
        subtitle: tr('add_ons.period_calendar.subtitle'),
        displayPrice: getActiveDeal(AppProduct.period_calendar).displayPrice,
        displayComparePrice: getActiveDeal(AppProduct.period_calendar).displayComparePrice,
        badgeLabel: getActiveDeal(AppProduct.period_calendar).badgeLabel,
        iconData: SpIcons.waterDrop,
        weekdayColor: 7,
        demoImages: [
          '/add_ons_demos/period_calendar/period_calendar_1.jpg',
          '/add_ons_demos/period_calendar/period_calendar_2.jpg',
          '/add_ons_demos/period_calendar/period_calendar_3.jpg',
        ],
        onTry: null,
        designForFemale: true,
        onPurchased: () async {
          var eventCount = await EventDbModel.db.count(
            filters: {'event_type': 'period'},
            debugSource: '$runtimeType#onPurchased',
          );
          if (eventCount == 0) {
            await EventDbModel.period(date: DateTime.now().subtract(const Duration(days: 2))).createIfNotExist();
            await EventDbModel.period(date: DateTime.now().subtract(const Duration(days: 1))).createIfNotExist();
            await EventDbModel.period(date: DateTime.now()).createIfNotExist();
          }
        },
        onOpen: (BuildContext context) async {
          SpCalendarSheet(
            initialMonth: DateTime.now().month,
            initialYear: DateTime.now().year,
            initialSegment: CalendarSegmentId.period,
          ).show(context: context);
        },
      ),
    ];

    notifyListeners();
  }
}
