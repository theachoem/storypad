import 'package:easy_localization/easy_localization.dart';

enum PageLayoutType {
  list,
  pages;

  String get translatedName {
    switch (this) {
      case list:
        return tr('general.page_layout.list');
      case pages:
        return tr('general.page_layout.pages');
    }
  }
}
