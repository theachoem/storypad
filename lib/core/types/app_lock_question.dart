// ignore_for_file: constant_identifier_names

import 'package:easy_localization/easy_localization.dart' show tr;

enum AppLockQuestion {
  name_of_your_first_pet,
  city_or_town_your_were_born,
  favorite_childhood_friend,
  favorite_color,
  name_of_elementary_school,
  city_or_town_your_parent_met,
  name_of_your_first_teacher;

  String get translatedQuestion {
    switch (this) {
      case name_of_your_first_pet:
        return tr('general.security_question.name_of_your_first_pet');
      case city_or_town_your_were_born:
        return tr('general.security_question.city_or_town_your_were_born');
      case favorite_childhood_friend:
        return tr('general.security_question.favorite_childhood_friend');
      case favorite_color:
        return tr('general.security_question.favorite_color');
      case name_of_elementary_school:
        return tr('general.security_question.name_of_elementary_school');
      case city_or_town_your_parent_met:
        return tr('general.security_question.city_or_town_your_parent_met');
      case name_of_your_first_teacher:
        return tr('general.security_question.name_of_your_first_teacher');
    }
  }
}
