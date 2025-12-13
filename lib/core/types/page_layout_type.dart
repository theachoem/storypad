import 'package:easy_localization/easy_localization.dart';

enum PageLayoutType {
  list,
  grid,
  pages,
  ;

  String get translatedName {
    switch (this) {
      case list:
        return tr('general.page_layout.list');
      case grid:
        return tr('general.page_layout.grid');
      case pages:
        return tr('general.page_layout.pages');
    }
  }
}
