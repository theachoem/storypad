import 'package:storypad/core/objects/device_info_object.dart';

late final DeviceInfoObject kDeviceInfo;

class DeviceInfoInitializer {
  static Future<void> call() async {
    kDeviceInfo = await DeviceInfoObject.get();
  }
}
