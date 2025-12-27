import 'package:flutter/material.dart';
import 'package:storypad/core/types/feature_reward.dart';
import 'package:storypad/widgets/sp_icons.dart';

part 'reward_feature_object.dart';

class RewardObject {
  final int purchaseCount;
  final String rewardedBadge;
  final String rewardedIconPath;
  final List<RewardFeature> includedRewardedFeatures;
  final List<RewardFeatureObject> features;

  RewardObject({
    required this.purchaseCount,
    required this.rewardedBadge,
    required this.includedRewardedFeatures,
    required this.rewardedIconPath,
    required this.features,
  });

  // Level 0  → "Free"
  // Level 1  → "Bronze"
  // Level 2  → "Silver"
  // Level 3  → "Gold"
  // Level 4  → "Platinum"
  // Level 5  → "Diamond"
  // Level 6  → "Elite"
  // Level 7  → "Premium"
  // Level 8  → "Ultimate"
  // Level 10 → "Legendary"
  static final List<RewardObject> rewards = [
    RewardObject(
      purchaseCount: 0,
      rewardedBadge: 'Free',
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      includedRewardedFeatures: [],
      features: [],
    ),
    RewardObject(
      rewardedBadge: 'Bronze',
      purchaseCount: 1,
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      includedRewardedFeatures: [
        .writing_stats,
      ],
      features: [
        RewardFeatureObject(
          title: 'Writing Stats',
          description: 'View word and character count for your story',
          iconData: SpIcons.text,
          dayColor: 1,
          type: .writing_stats,
        ),
      ],
    ),
    RewardObject(
      rewardedBadge: 'Silver',
      purchaseCount: 2,
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      includedRewardedFeatures: [
        .writing_stats,
        .pinned_notes,
      ],
      features: [
        RewardFeatureObject(
          title: 'Pinned Notes',
          description: 'Keep your stories safe with automatic Google Drive sync',
          iconData: SpIcons.pinOutline,
          dayColor: 2,
          type: .pinned_notes,
        ),
      ],
    ),
    RewardObject(
      rewardedBadge: 'Gold',
      purchaseCount: 4,
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      includedRewardedFeatures: [
        .writing_stats,
        .pinned_notes,
        .auto_backups,
      ],
      features: [
        RewardFeatureObject(
          title: 'Automatic Backup',
          description: 'Keep your stories safe with automatic Google Drive sync',
          iconData: SpIcons.cloudDone,
          dayColor: 3,
          type: .auto_backups,
        ),
      ],
    ),
  ];
}
