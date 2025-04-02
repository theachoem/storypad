import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';

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
      return openCupertino(context);
    } else {
      return openMaterial(context);
    }
  }

  Future<T?> openMaterial<T>(BuildContext context) {
    return showModalBottomSheet<T>(
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      barrierColor: barrierColor,
      backgroundColor: getBackgroundColor(context),
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
            child: build(
              context,
              MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
        );
      },
    );
  }

  Future<T?> openCupertino<T>(BuildContext context) {
    if (fullScreen) {
      return showCupertinoSheet(
        context: context,
        pageBuilder: (context) {
          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeLeft: true,
            removeRight: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
              child: build(
                context,
                MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
              ),
            ),
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
            color: getBackgroundColor(context),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: build(
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
