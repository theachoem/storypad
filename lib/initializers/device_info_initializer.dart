import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class DeviceInfoInitializer {
  static Future<void> call() async {
    kDeviceInfo = await DeviceInfoObject.get();
  }
}
