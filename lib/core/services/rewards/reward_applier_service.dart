// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/storages/redeemed_reward_storage.dart';

class RewardApplierService {
  static const REDEEMED_AT_KEY = 'redeemed_at';
  static const ADD_ONS_KEY = 'add_ons';
  static const DURATION_IN_DAYS_KEY = 'duration_in_days';

  static Future<void> clearReward() async {
    await RedeemedRewardStorage().remove();
  }

  static Future<void> applyReward(String code) async {
    var rewardDoc = await FirebaseFirestore.instance.collection('rewards').doc(code).get();

    // validate data
    if (!rewardDoc.exists) throw 'Reward code not found';
    Map<String, dynamic>? data = rewardDoc.data();

    if (data == null) throw 'Invalid reward data';
    List<String> addOns = List<String>.from(data[ADD_ONS_KEY] ?? []);
    int? durationInDays = data[DURATION_IN_DAYS_KEY] is int ? data[DURATION_IN_DAYS_KEY] : null;

    if (addOns.isEmpty) throw 'No add-ons in reward';
    if (durationInDays == null) throw 'Invalid duration';
    if (DateTime.now().add(Duration(days: durationInDays)).isBefore(DateTime.now())) {
      throw 'Reward already expired';
    }

    // mark as redeemed
    if (data[REDEEMED_AT_KEY] == null) {
      await rewardDoc.reference.update({
        REDEEMED_AT_KEY: FieldValue.serverTimestamp(),
      });
    }

    // mark device as redeemed
    var redeemDeviceInfoRef = await rewardDoc.reference.collection('redeemed_devices').doc(kDeviceInfo.id).get();
    if (!redeemDeviceInfoRef.exists) {
      await redeemDeviceInfoRef.reference.set({
        REDEEMED_AT_KEY: FieldValue.serverTimestamp(),
      });
    }

    // store locally
    await RedeemedRewardStorage().writeReward(
      addOns: addOns,
      expiredAt: DateTime.now().add(Duration(days: durationInDays)),
    );
  }
}
