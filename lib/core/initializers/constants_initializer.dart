import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/device_info_object.dart';
import 'package:storypad/core/services/app_logo_service.dart';

class ConstantsInitializer {
  static Future<void> call() async {
    kSupportDirectory = await _getDirectoryOrFallback(
      getApplicationSupportDirectory,
      Directory('${_homeDirectory.path}/.local/share/storypad'),
    );

    kApplicationDirectory =
        (Platform.isAndroid ? await getExternalStorageDirectory() : null) ??
        await _getDirectoryOrFallback(
          getApplicationDocumentsDirectory,
          Directory('${_homeDirectory.path}/Documents/StoryPad'),
        );

    kPackageInfo = await PackageInfo.fromPlatform();
    kDeviceInfo = await DeviceInfoObject.get();

    /// package:flutter/src/widgets/editable_text.dart [_processTextActions]
    kProcessTextActions = await DefaultProcessTextService().queryTextActions();
    kLocalTimezone = await _getLocalTimezone();
    kAppLogo = await AppLogoService().getCurrent();
  }

  /// Never throws: a device that won't report its timezone just falls back to
  /// whatever the caller does without one.
  static Future<String?> _getLocalTimezone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return null;
    }
  }

  static Directory get _homeDirectory {
    return Directory(Platform.environment['HOME'] ?? Directory.current.path);
  }

  static Future<Directory> _getDirectoryOrFallback(
    Future<Directory> Function() getter,
    Directory fallback,
  ) async {
    try {
      return await getter();
    } catch (_) {
      if (Platform.isLinux) return fallback;
      rethrow;
    }
  }
}
