import 'dart:io';
import 'dart:math';

import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/storages/base_object_storages/string_storage.dart';

/// Random per-install ID that keys gallery template usage counts in Firestore.
///
/// [kDeviceInfo.id] can't be used on Android: device_info_plus's `id` is the OS
/// build label (e.g. `UE1A.230829.036`), shared by every device on that build.
/// iOS seeds it with `identifierForVendor` so existing counts stay continuous.
class TemplateUsageInstallIdStorage extends StringStorage {
  Future<String> readOrCreate() async {
    final existing = await read();
    if (existing != null && existing.isNotEmpty) return existing;

    final seeded = Platform.isIOS ? kDeviceInfo.id : '';
    final id = seeded.isNotEmpty ? seeded : _randomId();
    await write(id);
    return id;
  }

  String _randomId() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
