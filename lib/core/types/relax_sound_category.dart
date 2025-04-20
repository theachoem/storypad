import 'package:easy_localization/easy_localization.dart';

enum RelaxSoundCategory {
  rainy,
  forest,
  water,
  animal;

  String get label {
    switch (this) {
      case rainy:
        return tr('sounds.category.rainy');
      case forest:
        return tr('sounds.category.forest');
      case water:
        return tr('sounds.category.water');
      case animal:
        return tr('sounds.category.animal');
    }
  }
}
