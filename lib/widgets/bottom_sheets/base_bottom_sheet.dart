import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/bottom_sheets/sp_cupertino_full_page_sheet_configurations.dart';

abstract class BaseBottomSheet {
  const BaseBottomSheet();

  String get className => runtimeType.toString();

  String get analyticScreenName => className.replaceAll("BottomSheet", "");
  String get analyticScreenClass => className;

  Color? get barrierColor => null;

  bool get fullScreen;

  Color? getBackgroundColor(BuildContext context) => null;

  Future<T?> show<T>({
    required BuildContext context,
  }) {
    AnalyticsService.instance.logViewSheet(bottomSheet: this);

    if (AppTheme.isCupertino(context)) {
      return openCupertino(
        backgroundColor: getBackgroundColor(context),
        context: context,
        fullScreen: fullScreen,
        builder: (context, bottomPadding) => build(context, bottomPadding),
      );
    } else {
      return openMaterial(
        context: context,
        barrierColor: barrierColor,
        backgroundColor: getBackgroundColor(context),
        builder: (context, bottomPadding) => build(context, bottomPadding),
      );
    }
  }

  static Future<T?> openMaterial<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, double bottomPadding) builder,
    Color? barrierColor,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      barrierColor: barrierColor,
      backgroundColor: backgroundColor,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
          ),
          // No need left or right default padding for sheet.
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: builder(
              context,
              MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
        );
      },
    );
  }

  static Future<T?> openCupertino<T>({
    required BuildContext context,
    required bool fullScreen,
    required Widget Function(BuildContext context, double bottomPadding) builder,
    Color? backgroundColor,
  }) {
    if (fullScreen) {
      return showCupertinoSheet(
        context: context,
        pageBuilder: (context) {
          return SpCupertinoFullPageSheetConfigurations(
            child: builder(context, MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom),
          );
        },
      );
    }

    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeRight: true,
          child: Material(
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: builder(
                context,
                MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
              ),
            ),
          ),
        );
      },
    );
  }

  // IOS already have animation when open keyboard.
  Widget buildBottomPadding(double bottomPadding) {
    if (Platform.isIOS || Platform.isMacOS) {
      return SizedBox(height: bottomPadding);
    } else {
      return AnimatedContainer(
        curve: Curves.fastEaseInToSlowEaseOut,
        duration: Durations.long2,
        height: bottomPadding,
      );
    }
  }

  Widget build(BuildContext context, double bottomPadding);
}
