import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'languages_view.dart';

class LanguagesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final LanguagesRoute params;

  late final List<Locale> supportedLocales;

  LanguagesViewModel({
    required this.params,
    required BuildContext context,
  }) {
    supportedLocales = getSupportedLocales(context);
  }

  List<Locale> getSupportedLocales(BuildContext context) {
    List<Locale> supportedLocales =
        context.findAncestorWidgetOfExactType<MaterialApp>()?.supportedLocales.toList() ?? [];

    // eg. en_US
    String? languageCode = Intl.systemLocale.split("_").firstOrNull;
    supportedLocales.sort((a, b) {
      if (a.languageCode == languageCode) {
        return -1;
      } else if (a.languageCode == languageCode) {
        return 1;
      } else {
        return a.languageCode.compareTo(b.languageCode);
      }
    });

    return supportedLocales;
  }
}
