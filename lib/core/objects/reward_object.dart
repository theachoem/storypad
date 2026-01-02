import 'package:easy_localization/easy_localization.dart';
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
  // Level 3  → "Gold" tr('general.user_type.gold')
  // Level 4  → "Platinum"
  // Level 5  → "Diamond"
  // Level 6  → "Elite"
  // Level 7  → "Premium"
  // Level 8  → "Ultimate"
  // Level 10 → "Legendary"
  static List<RewardObject> get rewards => [
    RewardObject(
      purchaseCount: 0,
      rewardedBadge: tr('general.user_type.free'),
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_trophy_56x56.png',
      includedRewardedFeatures: [],
      features: [],
    ),
    RewardObject(
      rewardedBadge: tr('general.user_type.pro'),
      purchaseCount: 1,
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_trophy_56x56.png',
      includedRewardedFeatures: [
        .writing_stats,
        .pinned_notes,
        .auto_backups,
      ],
      features: [
        RewardFeatureObject(
          title: tr('list_tile.reward_writing_state_feature.title'),
          subtitle: tr('list_tile.reward_writing_state_feature.subtitle'),
          iconData: SpIcons.text,
          dayColor: 1,
          videoUrlPath: '/reward_feature_videos/writing_stats.mp4',
          type: .writing_stats,
        ),
        RewardFeatureObject(
          title: tr('list_tile.reward_pinned_note_feature.title'),
          subtitle: tr('list_tile.reward_pinned_note_feature.subtitle'),
          iconData: SpIcons.pinOutline,
          dayColor: 2,
          videoUrlPath: '/reward_feature_videos/pinned_notes.mp4',
          type: .pinned_notes,
        ),
        RewardFeatureObject(
          title: tr('list_tile.reward_automatic_backup.title'),
          subtitle: tr('list_tile.reward_automatic_backup.subtitle'),
          iconData: SpIcons.cloudDone,
          dayColor: 3,
          videoUrlPath: '/reward_feature_videos/auto_backups.mp4',
          type: .auto_backups,
        ),
      ],
    ),
    // RewardObject(
    //   rewardedBadge: tr('general.user_type.silver'),
    //   purchaseCount: 3,
    //   rewardedIconPath: '/icons/hand_drawn/hand_drawn_trophy_56x56.png',
    //   includedRewardedFeatures: [
    //     .writing_stats,
    //     .pinned_notes,
    //     .auto_backups,
    //   ],
    //   features: [
    //     RewardFeatureObject(
    //       title: tr('list_tile.reward_pinned_note_feature.title'),
    //       subtitle: tr('list_tile.reward_pinned_note_feature.subtitle'),
    //       iconData: SpIcons.pinOutline,
    //       dayColor: 2,
    //       videoUrlPath: '/reward_feature_videos/pinned_notes.mp4',
    //       type: .pinned_notes,
    //     ),
    //     RewardFeatureObject(
    //       title: tr('list_tile.reward_automatic_backup.title'),
    //       subtitle: tr('list_tile.reward_automatic_backup.subtitle'),
    //       iconData: SpIcons.cloudDone,
    //       dayColor: 3,
    //       videoUrlPath: '/reward_feature_videos/auto_backups.mp4',
    //       type: .auto_backups,
    //     ),
    //   ],
    // ),
  ];
}
