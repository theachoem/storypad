import 'dart:ui';

class AppLocale {
  final Locale locale;
  final String name;
  final String nativeName;

  const AppLocale(
    this.locale,
    this.name,
    this.nativeName,
  );

  static const Locale fallbackLocale = Locale('en');
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('km'),
    Locale('ar'),
  ];

  static const Map<String, AppLocale> supportedLocalesWithTranslation = {
    "en": AppLocale(Locale('en'), 'English', 'English'),
    "km": AppLocale(Locale('km'), 'Khmer', 'ភាសាខ្មែរ'),
    "ar": AppLocale(Locale('ar'), 'Arabic', 'العربية')
  };

  static String getLanguageNativeName(Locale locale) {
    return supportedLocalesWithTranslation[locale.toLanguageTag()]?.nativeName ?? locale.toLanguageTag();
  }
}
