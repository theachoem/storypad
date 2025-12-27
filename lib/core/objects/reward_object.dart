import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';

part 'reward_feature_object.dart';

class RewardObject {
  final int purchaseCount;
  final String rewardedTitle;
  final String rewardedMessage;
  final String rewardedIconPath;
  final List<RewardFeatureObject> features;

  RewardObject({
    required this.purchaseCount,
    required this.rewardedTitle,
    required this.rewardedMessage,
    required this.rewardedIconPath,
    required this.features,
  });

  static final List<RewardObject> rewards = [
    RewardObject(
      purchaseCount: 0,
      rewardedTitle: 'You are exploring StoryPad!',
      rewardedMessage: 'Start your journaling journey and unlock rewards.',
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      features: [],
    ),
    RewardObject(
      purchaseCount: 1,
      rewardedTitle: 'You are a mindful writer!',
      rewardedMessage: 'You\'re building a meaningful reflection practice.',
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      features: [
        RewardFeatureObject(
          title: 'Writing Stats',
          description: 'View word and character count for your story',
          iconData: SpIcons.text,
        ),
      ],
    ),
    RewardObject(
      purchaseCount: 2,
      rewardedTitle: 'Your commitment to self-discovery is growing.',
      rewardedMessage: 'Your commitment to self-discovery is growing.',
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      features: [
        RewardFeatureObject(
          title: 'Pinned Notes',
          description: 'Keep your stories safe with automatic Google Drive sync',
          iconData: SpIcons.pinOutline,
        ),
      ],
    ),
    RewardObject(
      purchaseCount: 4,
      rewardedTitle: 'Passionate Keeper',
      rewardedMessage: 'You\'re creating a rich tapestry of memories.',
      rewardedIconPath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
      features: [
        RewardFeatureObject(
          title: 'Automatic Backup',
          description: 'Keep your stories safe with automatic Google Drive sync',
          iconData: SpIcons.cloudDone,
        ),
      ],
    ),
  ];
}
