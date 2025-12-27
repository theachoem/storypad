part of 'reward_object.dart';

class RewardFeatureObject {
  final String title;
  final String description;
  final IconData iconData;
  final int dayColor;
  final RewardFeature type;

  RewardFeatureObject({
    required this.title,
    required this.description,
    required this.iconData,
    required this.dayColor,
    required this.type,
  });
}
