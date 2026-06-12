import 'package:easy_localization/easy_localization.dart';

enum FontSizeOption {
  small,
  normal,
  large,
  extraLarge;

  String get label {
    switch (this) {
      case FontSizeOption.small:
        return tr('general.size_small');
      case FontSizeOption.normal:
        return tr('general.size_normal');
      case FontSizeOption.large:
        return tr('general.size_large');
      case FontSizeOption.extraLarge:
        return tr('general.size_extra_large');
    }
  }
}
