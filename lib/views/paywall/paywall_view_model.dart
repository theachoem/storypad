import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/paywall_feature_object.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/import_export/import_export_view.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'paywall_view.dart';

class PaywallViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PaywallRoute params;
  final BuildContext context;
  final List<GlobalKey> featureKeys = List.generate(PaywallFeature.values.length, (_) => GlobalKey());

  late final ValueNotifier<PaywallFeature?> focusingFeatureNotifer = ValueNotifier(params.initialFocus);
  List<PaywallFeatureObject>? features;

  PaywallViewModel({
    required this.params,
    required this.context,
  }) {
    load(context).then((_) {
      if (focusingFeatureNotifer.value != null) {
        Future.delayed(Durations.long2, () {
          focusOn(focusingFeatureNotifer.value!);
        });
      }
    });
  }

  Future<void> focusOn(PaywallFeature focusFeature) async {
    await Scrollable.ensureVisible(
      featureKeys[focusFeature.index].currentContext!,
      curve: Curves.ease,
      duration: Durations.medium1,
      alignment: 0.5,
    );

    Future.delayed(Durations.long2, () {
      if (!disposed) focusingFeatureNotifer.value = null;
    });
  }

  Future<void> load(BuildContext context) async {
    await context.read<InAppPurchaseProvider>().fetchAndCacheProducts(debugSource: '$runtimeType#load');

    features = [
      PaywallFeatureObject(
        type: PaywallFeature.backgrounds,
        title: tr('paywall_features.backgrounds.title'),
        subtitle: tr('paywall_features.backgrounds.subtitle'),
        iconData: SpIcons.theme,
        weekdayColor: 2,
        demoImages: [
          '/feature_demos/backgrounds/backgrounds_1.jpg',
          '/feature_demos/backgrounds/backgrounds_2.jpg',
        ],
        onOpen: null,
      ),
      PaywallFeatureObject(
        type: PaywallFeature.voice_journal,
        title: tr('paywall_features.voice_journal.title'),
        subtitle: tr('paywall_features.voice_journal.subtitle'),
        iconData: SpIcons.voice,
        weekdayColor: 5,
        demoImages: [
          '/feature_demos/voice_journal/voice_journal_1.jpg',
          '/feature_demos/voice_journal/voice_journal_2.jpg',
          '/feature_demos/voice_journal/voice_journal_3.jpg',
        ],
        onOpen: null,
      ),
      PaywallFeatureObject(
        type: PaywallFeature.templates,
        title: tr('paywall_features.templates.title'),
        subtitle: tr('paywall_features.templates.subtitle'),
        iconData: SpIcons.lightBulb,
        weekdayColor: 1,
        demoImages: [
          '/feature_demos/templates/template_1.jpg',
          '/feature_demos/templates/template_2.jpg',
          '/feature_demos/templates/template_3.jpg',
          '/feature_demos/templates/template_4.jpg',
        ],
        onOpen: (BuildContext context) => const TemplatesRoute().push(context),
      ),
      PaywallFeatureObject(
        type: PaywallFeature.relax_sounds,
        title: tr('paywall_features.relax_sounds.title'),
        subtitle: tr('paywall_features.relax_sounds.subtitle'),
        iconData: SpIcons.musicNote,
        weekdayColor: 4,
        demoImages: [
          '/feature_demos/relax_sounds/relax_sound_1.jpg',
          '/feature_demos/relax_sounds/relax_sound_2.jpg',
          '/feature_demos/relax_sounds/relax_sound_3.jpg',
          '/feature_demos/relax_sounds/relax_sound_4.jpg',
        ],
        onOpen: (BuildContext context) => const RelaxSoundsRoute().push(context),
      ),
      PaywallFeatureObject(
        type: PaywallFeature.markdown_export,
        title: tr('paywall_features.markdown_export.title'),
        subtitle: tr('paywall_features.markdown_export.subtitle'),
        iconData: SpIcons.markdown,
        weekdayColor: 6,
        demoImages: [
          '/feature_demos/markdown_export/markdown_export_1.jpg',
          '/feature_demos/markdown_export/markdown_export_2.jpg',
          '/feature_demos/markdown_export/markdown_export_3.jpg',
          '/feature_demos/markdown_export/markdown_export_4.jpg',
          '/feature_demos/markdown_export/markdown_export_5.jpg',
        ],
        onOpen: (BuildContext context) => const ImportExportRoute(initialExportOption: .markdown).push(context),
      ),
      PaywallFeatureObject(
        type: PaywallFeature.writing_stats,
        title: tr('paywall_features.writing_stats.title'),
        subtitle: tr('paywall_features.writing_stats.subtitle'),
        iconData: SpIcons.text,
        weekdayColor: 7,
        demoImages: [
          '/feature_demos/writing_stats/writing_stats_1.jpg',
          '/feature_demos/writing_stats/writing_stats_2.jpg',
        ],
        onOpen: null,
      ),
      PaywallFeatureObject(
        type: PaywallFeature.pinned_notes,
        title: tr('paywall_features.pinned_notes.title'),
        subtitle: tr('paywall_features.pinned_notes.subtitle'),
        iconData: SpIcons.pinOutline,
        weekdayColor: 1,
        demoImages: [
          '/feature_demos/pinned_notes/pinned_notes_1.jpg',
          '/feature_demos/pinned_notes/pinned_notes_2.jpg',
        ],
        onOpen: null,
      ),
      PaywallFeatureObject(
        type: PaywallFeature.auto_backups,
        title: tr('paywall_features.auto_backups.title'),
        subtitle: tr('paywall_features.auto_backups.subtitle'),
        iconData: SpIcons.cloudDone,
        weekdayColor: 4,
        demoImages: [
          '/feature_demos/auto_backups/auto_backups_1.jpg',
        ],
        onOpen: null,
      ),
    ];

    preloadUrls();

    notifyListeners();
  }

  void preloadUrls() {
    // getDownloadUrl already handle completer to prevent duplicate download for same urlPath
    // So UI, can call getDownloadURL again to get this preloaded completer.
    for (PaywallFeatureObject feature in features ?? []) {
      for (String urlPath in feature.demoImages) {
        FirestoreStorageService.instance.getDownloadURL(urlPath);
      }
    }
  }

  @override
  void dispose() {
    focusingFeatureNotifer.dispose();
    super.dispose();
  }
}
