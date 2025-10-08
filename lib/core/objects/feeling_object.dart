// ignore_for_file: constant_identifier_names

import 'package:easy_localization/easy_localization.dart' show tr;
import 'package:flutter/material.dart' show BuildContext;
import 'package:storypad/gen/assets.gen.dart' show AssetGenImage, Assets;

part '../types/feeling_group.dart';

class FeelingObject {
  final String value;
  final String Function(BuildContext context) translation;
  final AssetGenImage image64;

  FeelingObject({
    required this.value,
    required this.translation,
    required this.image64,
  });

  static const Map<FeelingGroup, List<String>> feelignGroups = {
    FeelingGroup.joy: [
      'positive_feelings',
      'smiling_halo',
      'cheerfulness',
      'beaming',
      'smiling_broadly',
      'laughter',
      'really_funny',
      'winking',
      'in_love',
      'lovely',
      'blowing',
      'cuteness',
      'annoy_someone',
      'savoring_food',
      'crazy',
      'zany',
      'something_cool',
      'excited',
      'getting_rich',
    ],
    FeelingGroup.sadness: [
      'crying',
      'loudly_crying',
      'downcast',
      'disappointed',
      'tired',
    ],
    FeelingGroup.fear: [
      'nervousness',
      'fearful',
      'worry',
      'grinning_sweat',
    ],
    FeelingGroup.anger: [
      'serious',
      'pouting',
      'mistrust',
    ],
    FeelingGroup.neutral: [
      'neutral',
      'slightly_smiling',
      'confused',
      'expressionless',
      'head_bandage',
      'medical_mask',
      'speechlessness',
      'flushed',
      'rolling_eyes',
    ],
    FeelingGroup.other: [
      'nerd',
      'monocle',
      'sleeping',
      'dizzy',
      'suggestive_smile',
      'wow',
      'devil',
      'drooling',
      'vomiting',
      'nauseated',
    ],
  };

  static final Map<String, FeelingObject> feelingsByKey = {
    "beaming": FeelingObject(
      value: "beaming",
      translation: (context) => tr("general.feeling.beaming", context: context),
      image64: Assets.emoji64.beamingFaceWithSmilingEyes64x641395554,
    ),
    "worry": FeelingObject(
      value: "worry",
      translation: (context) => tr("general.feeling.worry", context: context),
      image64: Assets.emoji64.confoundedFace64x641395561,
    ),
    "confused": FeelingObject(
      value: "confused",
      translation: (context) => tr("general.feeling.confused", context: context),
      image64: Assets.emoji64.confusedFace64x641395584,
    ),
    "crying": FeelingObject(
      value: "crying",
      translation: (context) => tr("general.feeling.crying", context: context),
      image64: Assets.emoji64.cryingFace64x641395579,
    ),
    "disappointed": FeelingObject(
      value: "disappointed",
      translation: (context) => tr("general.feeling.disappointed", context: context),
      image64: Assets.emoji64.disappointedFace64x641395587,
    ),
    "dizzy": FeelingObject(
      value: "dizzy",
      translation: (context) => tr("general.feeling.dizzy", context: context),
      image64: Assets.emoji64.dizzyFace64x641395573,
    ),
    "downcast": FeelingObject(
      value: "downcast",
      translation: (context) => tr("general.feeling.downcast", context: context),
      image64: Assets.emoji64.downcastFaceWithSweat64x641395586,
    ),
    "drooling": FeelingObject(
      value: "drooling",
      translation: (context) => tr("general.feeling.drooling", context: context),
      image64: Assets.emoji64.droolingFace64x641395566,
    ),
    "expressionless": FeelingObject(
      value: "expressionless",
      translation: (context) => tr("general.feeling.expressionless", context: context),
      image64: Assets.emoji64.expressionlessFace64x641395580,
    ),
    "blowing": FeelingObject(
      value: "blowing",
      translation: (context) => tr("general.feeling.blowing", context: context),
      image64: Assets.emoji64.faceBlowingAKiss64x641395556,
    ),
    "savoring_food": FeelingObject(
      value: "savoring_food",
      translation: (context) => tr("general.feeling.savoring_food", context: context),
      image64: Assets.emoji64.faceSavoringFood64x641395567,
    ),
    "vomiting": FeelingObject(
      value: "vomiting",
      translation: (context) => tr("general.feeling.vomiting", context: context),
      image64: Assets.emoji64.faceVomiting64x641395569,
    ),
    "head_bandage": FeelingObject(
      value: "head_bandage",
      translation: (context) => tr("general.feeling.head_bandage", context: context),
      image64: Assets.emoji64.faceWithHeadBandage64x641395563,
    ),
    "medical_mask": FeelingObject(
      value: "medical_mask",
      translation: (context) => tr("general.feeling.medical_mask", context: context),
      image64: Assets.emoji64.faceWithMedicalMask64x641395570,
    ),
    "monocle": FeelingObject(
      value: "monocle",
      translation: (context) => tr("general.feeling.monocle", context: context),
      image64: Assets.emoji64.faceWithMonocle64x641395562,
    ),
    "wow": FeelingObject(
      value: "wow",
      translation: (context) => tr("general.feeling.wow", context: context),
      image64: Assets.emoji64.faceWithOpenMouth64x641395578,
    ),
    "mistrust": FeelingObject(
      value: "mistrust",
      translation: (context) => tr("general.feeling.mistrust", context: context),
      image64: Assets.emoji64.faceWithRaisedEyebrow64x641395571,
    ),
    "rolling_eyes": FeelingObject(
      value: "rolling_eyes",
      translation: (context) => tr("general.feeling.rolling_eyes", context: context),
      image64: Assets.emoji64.faceWithRollingEyes64x641395546,
    ),
    "serious": FeelingObject(
      value: "serious",
      translation: (context) => tr("general.feeling.serious", context: context),
      image64: Assets.emoji64.faceWithSymbolsOnMouth64x641395550,
    ),
    "really_funny": FeelingObject(
      value: "really_funny",
      translation: (context) => tr("general.feeling.really_funny", context: context),
      image64: Assets.emoji64.faceWithTearsOfJoy64x641395560,
    ),
    "cuteness": FeelingObject(
      value: "cuteness",
      translation: (context) => tr("general.feeling.cuteness", context: context),
      image64: Assets.emoji64.faceWithTongue64x641395588,
    ),
    "speechlessness": FeelingObject(
      value: "speechlessness",
      translation: (context) => tr("general.feeling.speechlessness", context: context),
      image64: Assets.emoji64.faceWithoutMouth64x641395577,
    ),
    "fearful": FeelingObject(
      value: "fearful",
      translation: (context) => tr("general.feeling.fearful", context: context),
      image64: Assets.emoji64.fearfulFace64x641395553,
    ),
    "flushed": FeelingObject(
      value: "flushed",
      translation: (context) => tr("general.feeling.flushed", context: context),
      image64: Assets.emoji64.flushedFace64x641395564,
    ),
    "nervousness": FeelingObject(
      value: "nervousness",
      translation: (context) => tr("general.feeling.nervousness", context: context),
      image64: Assets.emoji64.grimacingFace64x641395576,
    ),
    "cheerfulness": FeelingObject(
      value: "cheerfulness",
      translation: (context) => tr("general.feeling.cheerfulness", context: context),
      image64: Assets.emoji64.grinningFace64x641395591,
    ),
    "grinning_sweat": FeelingObject(
      value: "grinning_sweat",
      translation: (context) => tr("general.feeling.grinning_sweat", context: context),
      image64: Assets.emoji64.grinningFaceWithSweat64x641395555,
    ),
    "smiling_broadly": FeelingObject(
      value: "smiling_broadly",
      translation: (context) => tr("general.feeling.smiling_broadly", context: context),
      image64: Assets.emoji64.grinningFaceWithSmilingEyes64x641395548,
    ),
    "laughter": FeelingObject(
      value: "laughter",
      translation: (context) => tr("general.feeling.laughter", context: context),
      image64: Assets.emoji64.grinningSquintingFace64x641395574,
    ),
    "loudly_crying": FeelingObject(
      value: "loudly_crying",
      translation: (context) => tr("general.feeling.loudly_crying", context: context),
      image64: Assets.emoji64.loudlyCryingFace64x641395592,
    ),
    "getting_rich": FeelingObject(
      value: "getting_rich",
      translation: (context) => tr("general.feeling.getting_rich", context: context),
      image64: Assets.emoji64.moneyMouthFace64x641395557,
    ),
    "nauseated": FeelingObject(
      value: "nauseated",
      translation: (context) => tr("general.feeling.nauseated", context: context),
      image64: Assets.emoji64.nauseatedFace64x641395559,
    ),
    "nerd": FeelingObject(
      value: "nerd",
      translation: (context) => tr("general.feeling.nerd", context: context),
      image64: Assets.emoji64.nerdFace64x641395568,
    ),
    "neutral": FeelingObject(
      value: "neutral",
      translation: (context) => tr("general.feeling.neutral", context: context),
      image64: Assets.emoji64.neutralFace64x641395585,
    ),
    "pouting": FeelingObject(
      value: "pouting",
      translation: (context) => tr("general.feeling.pouting", context: context),
      image64: Assets.emoji64.poutingFace64x641395575,
    ),
    "sleeping": FeelingObject(
      value: "sleeping",
      translation: (context) => tr("general.feeling.sleeping", context: context),
      image64: Assets.emoji64.sleepingFace64x641395590,
    ),
    "slightly_smiling": FeelingObject(
      value: "slightly_smiling",
      translation: (context) => tr("general.feeling.slightly_smiling", context: context),
      image64: Assets.emoji64.slightlySmilingFace64x641395552,
    ),
    "smiling_halo": FeelingObject(
      value: "smiling_halo",
      translation: (context) => tr("general.feeling.smiling_halo", context: context),
      image64: Assets.emoji64.smilingFaceWithHalo64x641395582,
    ),
    "in_love": FeelingObject(
      value: "in_love",
      translation: (context) => tr("general.feeling.in_love", context: context),
      image64: Assets.emoji64.smilingFaceWithHeartEyes64x641395589,
    ),
    "lovely": FeelingObject(
      value: "lovely",
      translation: (context) => tr("general.feeling.lovely", context: context),
      image64: Assets.emoji64.smilingFaceWithHearts64x641395545,
    ),
    "devil": FeelingObject(
      value: "devil",
      translation: (context) => tr("general.feeling.devil", context: context),
      image64: Assets.emoji64.smilingFaceWithHorns64x641395558,
    ),
    "positive_feelings": FeelingObject(
      value: "positive_feelings",
      translation: (context) => tr("general.feeling.positive_feelings", context: context),
      image64: Assets.emoji64.smilingFaceWithSmilingEyes64x641395594,
    ),
    "something_cool": FeelingObject(
      value: "something_cool",
      translation: (context) => tr("general.feeling.something_cool", context: context),
      image64: Assets.emoji64.smilingFaceWithSunglasses64x641395549,
    ),
    "suggestive_smile": FeelingObject(
      value: "suggestive_smile",
      translation: (context) => tr("general.feeling.suggestive_smile", context: context),
      image64: Assets.emoji64.smirkingFace64x641395593,
    ),
    "annoy_someone": FeelingObject(
      value: "annoy_someone",
      translation: (context) => tr("general.feeling.annoy_someone", context: context),
      image64: Assets.emoji64.squintingFaceWithTongue64x641395581,
    ),
    "excited": FeelingObject(
      value: "excited",
      translation: (context) => tr("general.feeling.excited", context: context),
      image64: Assets.emoji64.starStruck64x641395565,
    ),
    "tired": FeelingObject(
      value: "tired",
      translation: (context) => tr("general.feeling.tired", context: context),
      image64: Assets.emoji64.tiredFace64x641395547,
    ),
    "crazy": FeelingObject(
      value: "crazy",
      translation: (context) => tr("general.feeling.crazy", context: context),
      image64: Assets.emoji64.winkingFace64x641395551,
    ),
    "winking": FeelingObject(
      value: "winking",
      translation: (context) => tr("general.feeling.winking", context: context),
      image64: Assets.emoji64.winkingFaceWithTongue64x641395583,
    ),
    "zany": FeelingObject(
      value: "zany",
      translation: (context) => tr("general.feeling.zany", context: context),
      image64: Assets.emoji64.zanyFace64x641395572,
    ),
  };
}
