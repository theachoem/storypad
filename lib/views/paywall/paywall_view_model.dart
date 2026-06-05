import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/paywall_feature_object.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';
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
    int? index = features?.indexWhere((feature) => feature.type == focusFeature);
    if (index != null && index > 4) {
      await Scrollable.ensureVisible(
        featureKeys[focusFeature.index].currentContext!,
        curve: Curves.ease,
        duration: Durations.medium1,
        alignment: 0.3,
      );
    }

    Future.delayed(Durations.long2, () {
      if (!disposed) focusingFeatureNotifer.value = null;
    });
  }

  Future<void> load(BuildContext context) async {
    await context.read<InAppPurchaseProvider>().fetchAndCacheProducts(debugSource: '$runtimeType#load');

    features = [
      PaywallFeatureObject(
        type: PaywallFeature.customizations,
        title: tr('paywall_features.customizations.title'),
        subtitle: tr('paywall_features.customizations.subtitle'),
        iconData: SpIcons.theme,
        weekdayColor: 3,
        demoImagePaths: [
          '/feature_demos/customizations/customization_1.jpg',
          '/feature_demos/customizations/customization_2.jpg',
          '/feature_demos/customizations/customization_3.jpg',
          '/feature_demos/customizations/customization_4.jpg',
          '/feature_demos/customizations/customization_5.jpg',
        ],
        onOpen: null,
      ),
      PaywallFeatureObject(
        type: PaywallFeature.backgrounds,
        title: tr('paywall_features.backgrounds.title'),
        subtitle: tr('paywall_features.backgrounds.subtitle'),
        iconData: SpIcons.photo,
        weekdayColor: 1,
        demoImagePaths: [
          '/feature_demos/backgrounds/backgrounds_1.jpg',
          '/feature_demos/backgrounds/backgrounds_2.jpg',
        ],
        onOpen: null,
      ),
      PaywallFeatureObject(
        type: PaywallFeature.templates,
        title: tr('paywall_features.templates.title'),
        subtitle: tr('paywall_features.templates.subtitle'),
        iconData: SpIcons.lightBulb,
        weekdayColor: 2,
        demoImagePaths: [
          '/feature_demos/templates/template_1.jpg',
          '/feature_demos/templates/template_2.jpg',
          '/feature_demos/templates/template_3.jpg',
          '/feature_demos/templates/template_4.jpg',
        ],
        onOpen: (BuildContext context) => const TemplatesRoute().push(context),
      ),

      PaywallFeatureObject(
        type: PaywallFeature.markdown_export,
        title: tr('paywall_features.markdown_export.title'),
        subtitle: tr('paywall_features.markdown_export.subtitle'),
        iconData: SpIcons.markdown,
        weekdayColor: 4,
        demoImagePaths: [
          '/feature_demos/markdown_export/markdown_export_1.jpg',
          '/feature_demos/markdown_export/markdown_export_2.jpg',
          '/feature_demos/markdown_export/markdown_export_3.jpg',
          '/feature_demos/markdown_export/markdown_export_4.jpg',
          '/feature_demos/markdown_export/markdown_export_5.jpg',
        ],
        onOpen: (BuildContext context) => const ImportExportRoute(initialExportOption: .markdown).push(context),
      ),
      PaywallFeatureObject(
        type: PaywallFeature.relax_sounds,
        title: tr('paywall_features.relax_sounds.title'),
        subtitle: tr('paywall_features.relax_sounds.subtitle'),
        iconData: SpIcons.musicNote,
        weekdayColor: 5,
        demoImagePaths: [
          '/feature_demos/relax_sounds/relax_sound_1.jpg',
          '/feature_demos/relax_sounds/relax_sound_2.jpg',
          '/feature_demos/relax_sounds/relax_sound_3.jpg',
          '/feature_demos/relax_sounds/relax_sound_4.jpg',
        ],
        onOpen: (BuildContext context) => const RelaxSoundsRoute().push(context),
      ),
    ];

    preloadFiles();

    notifyListeners();
  }

  void preloadFiles() {
    // downloadFile deduplicates requests using completers, so calling this
    // from multiple screens is safe and helps images be ready sooner.
    for (PaywallFeatureObject feature in features ?? []) {
      for (String urlPath in feature.demoImagePaths) {
        CloudStorageService.instance.downloadFile(urlPath);
      }
    }
  }

  @override
  void dispose() {
    focusingFeatureNotifer.dispose();
    super.dispose();
  }
}
