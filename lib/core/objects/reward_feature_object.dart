part of 'reward_object.dart';

class RewardFeatureObject {
  final String title;
  final String subtitle;
  final IconData iconData;
  final int dayColor;
  final RewardFeature type;

  RewardFeatureObject({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.dayColor,
    required this.type,
  });
}
