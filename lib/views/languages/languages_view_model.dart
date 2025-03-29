import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/analytics/analytics_user_propery_service.dart';

// ignore: depend_on_referenced_packages
import 'package:intl/intl_standalone.dart';

// ignore: implementation_imports, invalid_use_of_visible_for_testing_member
import 'package:easy_localization/src/easy_localization_controller.dart' show LocaleExtension;

import 'languages_view.dart';

class LanguagesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final LanguagesRoute params;

  late final List<Locale> supportedLocales;

  LanguagesViewModel({
    required this.params,
    required BuildContext context,
  }) {
    supportedLocales = getSupportedLocales(context);
    load();
  }

  bool isSystemLocale(Locale locale) => _deviceLocale != null && locale.supports(_deviceLocale!);
  bool get canSetToDeviceLocale =>
      _savedLocale != null && _deviceLocale != null && !_savedLocale!.supports(_deviceLocale!);

  Locale? _deviceLocale;
  Locale? _savedLocale;

  Future<void> load() async {
    await _loadDeviceLocale();
    await _loadSavedLocale();
    notifyListeners();
  }

  Future<void> _loadDeviceLocale() async {
    final foundPlatformLocale = await findSystemLocale();
    Locale deviceLocale = foundPlatformLocale.toLocale();
    _deviceLocale = supportedLocales.where((locale) => locale.supports(deviceLocale)).firstOrNull;
  }

  Future<void> _loadSavedLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final strLocale = preferences.getString('locale');
    _savedLocale = strLocale?.toLocale();
  }

  Future<void> useDeviceLocale(BuildContext context) async {
    if (_deviceLocale != null) context.setLocale(_deviceLocale!);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('locale');
    await load();
  }

  void setLocale(Locale locale, BuildContext context) {
    if (_deviceLocale != null && locale.supports(_deviceLocale!)) {
      useDeviceLocale(context);
    } else {
      context.setLocale(locale);
      load();
    }

    AnalyticsUserProperyService.instance.logSetLocale(newLocale: locale);
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
