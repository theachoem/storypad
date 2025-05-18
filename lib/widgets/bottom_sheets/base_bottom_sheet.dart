import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/bottom_sheets/sp_cupertino_full_page_sheet_configurations.dart';

abstract class BaseBottomSheet {
  const BaseBottomSheet();

  String get className => runtimeType.toString();

  String get analyticScreenName => className.replaceAll("BottomSheet", "");
  String get analyticScreenClass => className;

  Color? get barrierColor => null;
  bool get showMaterialDragHandle => true;

  double get cupertinoPaddingTop => 16.0;

  bool get fullScreen;

  Color? getBackgroundColor(BuildContext context) => null;

  Future<T?> show<T>({
    required BuildContext context,
  }) {
    AnalyticsService.instance.logViewSheet(bottomSheet: this);

    if (kIsCupertino) {
      return openCupertino(
        paddingTop: cupertinoPaddingTop,
        backgroundColor: getBackgroundColor(context),
        context: context,
        fullScreen: fullScreen,
        builder: (context, bottomPadding) => build(context, bottomPadding),
      );
    } else {
      return openMaterial(
        context: context,
        barrierColor: barrierColor,
        showDragHandle: showMaterialDragHandle,
        backgroundColor: getBackgroundColor(context),
        builder: (context, bottomPadding) => build(context, bottomPadding),
      );
    }
  }

  static Future<T?> openMaterial<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, double bottomPadding) builder,
    bool? showDragHandle,
    Color? barrierColor,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      useRootNavigator: true,
      context: context,
      showDragHandle: showDragHandle,
      isScrollControlled: true,
      barrierColor: barrierColor,
      backgroundColor: backgroundColor,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
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

  /// In each cupertio sheet page, make sure to:
  /// 1. Use PrimaryScrollController.maybeOf(context) if the content is scrollable,
  ///    so the user can drag to close the sheet.
  ///
  /// 2. Show the close button on the right instead of the default left.
  ///
  /// Example AppBar setup:
  /// ```
  /// AppBar(
  ///   automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
  ///   actions: [
  ///     if (CupertinoSheetRoute.hasParentSheet(context))
  ///       CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
  ///   ],
  /// )
  /// ```
  static Future<T?> openCupertino<T>({
    required BuildContext context,
    required bool fullScreen,
    required double paddingTop,
    required Widget Function(BuildContext context, double bottomPadding) builder,
    Color? backgroundColor,
  }) {
    if (fullScreen) {
      return showCupertinoSheet(
        context: context,
        pageBuilder: (context) {
          return SpCupertinoFullPageSheetConfigurations(
            child: Builder(builder: (context) {
              return builder(context, MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom);
            }),
          );
        },
      );
    }

    return showCupertinoModalPopup(
      context: context,
      semanticsDismissible: true,
      barrierDismissible: true,
      builder: (context) {
        return MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeRight: true,
          child: Material(
            color: backgroundColor,
            child: Padding(
              padding: EdgeInsets.only(
                top: paddingTop,
                left: MediaQuery.of(context).padding.left,
                right: MediaQuery.of(context).padding.right,
              ),
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
