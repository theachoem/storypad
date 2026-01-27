import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_cupertino_full_page_sheet_configurations.dart';

abstract class BaseBottomSheet {
  const BaseBottomSheet();

  String get className => runtimeType.toString();

  String get analyticScreenName => className.replaceAll("BottomSheet", "");
  String get analyticScreenClass => className;

  Color? get barrierColor => null;

  bool get showMaterialDragHandle => true;
  bool get barrierDismissible => true;

  double get cupertinoPaddingTop => 16.0;

  bool get fullScreen;

  Color? getBackgroundColor(BuildContext context) => null;

  Future<T?> showReplacement<T>({
    required BuildContext context,
    bool useRootNavigator = false,
  }) async {
    if (kIsCupertino) throw UnimplementedError('Replacement bottom sheet is not implemented for Cupertino.');

    AnalyticsService.instance.logViewSheet(bottomSheet: this);
    context.read<RootProvider>().setTemporaryHidden(true);

    T? result = await replaceModalBottomSheet<T>(
      useRootNavigator: useRootNavigator,
      context: context,
      showDragHandle: showMaterialDragHandle,
      isScrollControlled: true,
      barrierColor: barrierColor,
      backgroundColor: getBackgroundColor(context),
      sheetAnimationStyle: .noAnimation,
      isDismissible: barrierDismissible,
      enableDrag: barrierDismissible,
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
            child: build(
              context,
              MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
        );
      },
    );

    if (context.mounted) context.read<RootProvider>().setTemporaryHidden(false);
    return result;
  }

  Future<T?> show<T>({
    required BuildContext context,
    bool useRootNavigator = false,
  }) async {
    if (barrierDismissible == false) {
      assert(
        showMaterialDragHandle == false,
        'If barrierDismissible is false, showMaterialDragHandle must also be false to prevent user from dragging down to dismiss the sheet.',
      );
    }

    AnalyticsService.instance.logViewSheet(bottomSheet: this);
    context.read<RootProvider>().setTemporaryHidden(true);

    T? result;
    if (kIsCupertino) {
      result = await openCupertino(
        paddingTop: cupertinoPaddingTop,
        backgroundColor: getBackgroundColor(context),
        context: context,
        fullScreen: fullScreen,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        builder: (context, bottomPadding) => build(context, bottomPadding),
      );
    } else {
      result = await openMaterial(
        context: context,
        barrierColor: barrierColor,
        showDragHandle: showMaterialDragHandle,
        backgroundColor: getBackgroundColor(context),
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        builder: (context, bottomPadding) => build(context, bottomPadding),
      );
    }

    if (context.mounted) context.read<RootProvider>().setTemporaryHidden(false);
    return result;
  }

  static Future<T?> openMaterial<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, double bottomPadding) builder,
    bool? showDragHandle,
    Color? barrierColor,
    Color? backgroundColor,
    bool useRootNavigator = false,
    bool barrierDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      useRootNavigator: useRootNavigator,
      context: context,
      showDragHandle: showDragHandle,
      isDismissible: barrierDismissible,
      enableDrag: barrierDismissible,
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
    bool useRootNavigator = false,
    bool barrierDismissible = true,
  }) {
    if (fullScreen) {
      return showCupertinoSheet(
        context: context,
        builder: (context) {
          return SpCupertinoFullPageSheetConfigurations(
            context: context,
            child: Builder(
              builder: (context) {
                return builder(
                  context,
                  MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
                );
              },
            ),
          );
        },
      );
    }

    return showCupertinoModalPopup(
      context: context,
      semanticsDismissible: true,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
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

/// Complete copy of [showModalBottomSheet] but replaces the current route
/// instead of pushing a new one.
Future<T?> replaceModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) {
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  return navigator.pushReplacement(
    ModalBottomSheetRoute<T>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      isScrollControlled: isScrollControlled,
      scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
      barrierLabel: barrierLabel ?? localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      isDismissible: isDismissible,
      modalBarrierColor: barrierColor ?? Theme.of(context).bottomSheetTheme.modalBarrierColor,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      settings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      anchorPoint: anchorPoint,
      useSafeArea: useSafeArea,
      sheetAnimationStyle: sheetAnimationStyle,
      requestFocus: requestFocus,
    ),
  );
}
