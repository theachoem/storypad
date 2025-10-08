import 'package:storypad/core/storages/base_object_storages/map_storage.dart';

class RedeemedRewardStorage extends MapStorage {
  Future<void> writeReward({
    List<String> addOns = const [],
    DateTime? expiredAt,
  }) {
    return writeMap({
      'add_ons': addOns,
      'expired_at': expiredAt?.toIso8601String(),
    });
  }

  Future<DateTime?> getExpiredAt() async {
    Map<String, dynamic>? result = await readMap();
    if (result?['expired_at'] != null) {
      return DateTime.tryParse(result?['expired_at'] ?? '');
    }
    return null;
  }

  Future<List<String>?> availableAddOns() async {
    Map<String, dynamic>? result = await readMap();
    bool expired =
        result?['expired_at'] != null &&
        DateTime.tryParse(result?['expired_at'] ?? '')?.isBefore(DateTime.now()) == true;

    if (result == null) return null;
    if (expired) return null;

    if (result['add_ons'] is List) {
      return List<String>.from(result['add_ons']);
    }

    return null;
  }
}
