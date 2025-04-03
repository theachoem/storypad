part of '../objects/feeling_object.dart';

enum FeelingGroup {
  joy,
  sadness,
  fear,
  anger,
  neutral,
  other;

  String get translatedName {
    switch (this) {
      case FeelingGroup.joy:
        return tr("general.feeling_group.joy");
      case FeelingGroup.sadness:
        return tr("general.feeling_group.sadness");
      case FeelingGroup.fear:
        return tr("general.feeling_group.fear");
      case FeelingGroup.anger:
        return tr("general.feeling_group.anger");
      case FeelingGroup.neutral:
        return tr("general.feeling_group.neutral");
      case FeelingGroup.other:
        return tr("general.feeling_group.other");
    }
  }
}
