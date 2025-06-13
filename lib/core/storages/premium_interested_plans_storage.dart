import 'package:storypad/core/storages/base_object_storages/map_storage.dart';

class PremiumInterestedPlansStorage extends MapStorage {
  Future<void> toggleInterested(String planName) async {
    Map<String, dynamic> result = await readMap() ?? {};
    result[planName] = result[planName] != null ? null : DateTime.now().toIso8601String();
    await writeMap(result);
  }
}
