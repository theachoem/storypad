import 'dart:io';
import 'package:flutter/services.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/base_object_storages/enum_storage.dart';
import 'package:storypad/core/types/app_logo.dart';

class _AppLogoStorage extends EnumStorage<AppLogo> {
  @override
  List<AppLogo> get values => AppLogo.values;
}

class AppLogoService {
  static const _channel = MethodChannel('default_platform_channel');

  Future<AppLogo> getCurrent() async {
    return await _AppLogoStorage().readEnum() ?? AppLogo.storypad_1_0;
  }

  Future<bool> set(AppLogo logo) async {
    if (logo == AppLogo.values.first) {
      return reset();
    }

    bool set = false;
    try {
      await _channel.invokeMethod('AppLogoService.set', {
        if (Platform.isIOS) 'xcodeLogoName': logo.xcodeLogoName,
        if (Platform.isAndroid) 'androidActivityAliasName': logo.androidActivityAliasName,
      });

      set = true;
    } catch (e) {
      AppLogger.error(e.toString(), stackTrace: e is Error ? e.stackTrace : null, tag: 'AppLogoService#set');
      set = false;
    }

    if (set) {
      await _AppLogoStorage().writeEnum(logo);
      kAppLogo = logo;
    }
    return set;
  }

  Future<bool> reset() async {
    bool cleared = false;

    try {
      await _channel.invokeMethod('AppLogoService.set', {
        if (Platform.isIOS) 'xcodeLogoName': null,
        if (Platform.isAndroid) 'androidActivityAliasName': AppLogo.values.first.androidActivityAliasName,
      });
      cleared = true;
    } catch (e) {
      AppLogger.error(e.toString(), stackTrace: e is Error ? e.stackTrace : null, tag: 'AppLogoService#reset');
      cleared = false;
    }

    if (cleared) {
      await _AppLogoStorage().remove();
      kAppLogo = AppLogo.storypad_1_0;
    }

    return cleared;
  }
}
