import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/add_on_object.dart';
import 'package:storypad/core/objects/calendar_segment_id.dart';
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

  StoreProduct? getProduct(String productIdentifier) =>
      context.read<InAppPurchaseProvider>().getProduct(productIdentifier);

  Future<void> load(BuildContext context) async {
    await context.read<InAppPurchaseProvider>().fetchAndCacheProducts(debugSource: '$runtimeType#load');

    addOns = [
      AddOnObject(
        type: AppProduct.voice_journal,
        title: tr('add_ons.voice_journal.title'),
        subtitle: tr('add_ons.voice_journal.subtitle'),
        displayPrice: getProduct('voice_journal')?.priceString,
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
        displayPrice: getProduct('templates')?.priceString,
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
        displayPrice: getProduct('relax_sounds')?.priceString,
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
        displayPrice: getProduct('period_calendar')?.priceString,
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
