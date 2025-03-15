import 'dart:io';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class ConstantsInitializer {
  static Future<void> call() async {
    kSupportDirectory = await getApplicationSupportDirectory();
    kApplicationDirectory =
        (Platform.isAndroid ? await getExternalStorageDirectory() : null) ?? await getApplicationDocumentsDirectory();

    kPackageInfo = await PackageInfo.fromPlatform();
    kDeviceInfo = await DeviceInfoObject.get();

    /// package:flutter/src/widgets/editable_text.dart [_processTextActions]
    kProcessTextActions = await DefaultProcessTextService().queryTextActions();
  }
}
