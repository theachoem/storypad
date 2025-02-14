import 'package:flutter/cupertino.dart';

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
  static const Map<String, Locale> supportedLocales = {
    'ar': Locale('ar'),
    'de-DE': Locale('de', 'DE'),
    'en': Locale('en'),
    'es-419': Locale('es', '419'),
    'es-ES': Locale('es', 'ES'),
    'fr-FR': Locale('fr', 'FR'),
    'hi-IN': Locale('hi', 'IN'),
    'id': Locale('id'),
    'it-IT': Locale('it', 'IT'),
    'ja-JP': Locale('ja', 'JP'),
    'km': Locale('km'),
    'ko-KR': Locale('ko', 'KR'),
    'pl-PL': Locale('pl', 'PL'),
    'pt-BR': Locale('pt', 'BR'),
    'th': Locale('th'),
    'vi-VN': Locale('vi', 'VN'),
    'zh-CN': Locale('zh', 'CN'),
  };

  static const Map<String, AppLocale> supportedLocalesWithTranslation = {
    "ar": AppLocale(Locale('ar'), 'Arabic', 'العربية'),
    "de-DE": AppLocale(Locale('de-DE'), 'German (Germany)', 'Deutsch (Deutschland)'),
    "en": AppLocale(Locale('en'), 'English', 'English'),
    "es-419": AppLocale(Locale('es', '419'), 'Spanish (Latin America)', 'Español (Latinoamérica)'),
    "es-ES": AppLocale(Locale('es', 'ES'), 'Spanish (Spain)', 'Español (España)'),
    "fr-FR": AppLocale(Locale('fr', 'FR'), 'French (France)', 'Français (France)'),
    "hi-IN": AppLocale(Locale('hi', 'IN'), 'Hindi (India)', 'हिन्दी (भारत)'),
    "id": AppLocale(Locale('id'), 'Indonesian', 'Bahasa Indonesia'),
    "it-IT": AppLocale(Locale('it', 'IT'), 'Italian (Italy)', 'Italiano (Italia)'),
    "ja-JP": AppLocale(Locale('ja', 'JP'), 'Japanese (Japan)', '日本語 (日本)'),
    "km": AppLocale(Locale('km'), 'Khmer', 'ភាសាខ្មែរ'),
    "ko-KR": AppLocale(Locale('ko', 'KR'), 'Korean (South Korea)', '한국어 (대한민국)'),
    "pl-PL": AppLocale(Locale('pl', 'PL'), 'Polish (Poland)', 'Polski (Polska)'),
    "pt-BR": AppLocale(Locale('pt', 'BR'), 'Portuguese (Brazil)', 'Português (Brasil)'),
    "th": AppLocale(Locale('th'), 'Thai', 'ไทย'),
    "vi-VN": AppLocale(Locale('vi', 'VN'), 'Vietnamese (Vietnam)', 'Tiếng Việt (Việt Nam)'),
    "zh-CN": AppLocale(Locale('zh', 'CN'), 'Chinese (Simplified)', '中文 (简体)'),
  };

  static String getLanguageNativeName(Locale locale) {
    assert(supportedLocalesWithTranslation.length == supportedLocales.length);
    assert(supportedLocalesWithTranslation.keys.join() == supportedLocales.keys.join());

    return supportedLocalesWithTranslation[locale.toLanguageTag()]?.nativeName ?? locale.toLanguageTag();
  }
}
