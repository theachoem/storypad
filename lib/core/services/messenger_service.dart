import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';

class MessengerService {
  final BuildContext context;

  MessengerService._({
    required this.context,
  });

  static MessengerService of(BuildContext context) {
    return MessengerService._(context: context);
  }

  ScaffoldMessengerState? get state {
    return ScaffoldMessenger.maybeOf(context);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? scaffoldFeatureController;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnackBar(
    String message, {
    bool success = true,
    SnackBarAction Function(Color? foreground)? action,
    bool showAction = true,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    clearSnackBars();

    Color? foreground = success ? null : Theme.of(context).colorScheme.onError;
    Color? background = success ? null : Theme.of(context).colorScheme.error;
    double? width = MediaQuery.of(context).size.width > 1000 ? 400.0 : null;

    scaffoldFeatureController = state?.showSnackBar(
      SnackBar(
        duration: duration,
        width: width,
        content: Text(message, style: TextStyle(color: foreground)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        dismissDirection: DismissDirection.horizontal,
        action: showAction
            ? action != null
                ? action(foreground)
                : SnackBarAction(
                    label: MaterialLocalizations.of(context).okButtonLabel,
                    textColor: foreground,
                    onPressed: () {},
                  )
            : null,
      ),
    );

    // When we our own custom ScaffoldMessager on end drawer instead of using Scaffold. SnackBar is not auto closed.
    // Manually close in this case.
    Future.delayed(duration + const Duration(milliseconds: 100)).then((_) {
      if (context.mounted) clearSnackBars();
    });

    return scaffoldFeatureController;
  }

  void clearSnackBars() {
    return state?.clearSnackBars();
  }

  void hideCurrentMaterialBanner() {
    return state?.hideCurrentMaterialBanner();
  }

  Future<void> showError([String? errorMessage]) async {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 1)).then((value) {
          if (context.mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        });

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpFadeIn.bound(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: ColorScheme.of(context).readOnly.surface3,
                  child: SpFadeIn.bound(
                    child: Icon(
                      SpIcons.errorCircle,
                      size: 56,
                      color: ColorScheme.of(context).bootstrap.danger.color,
                    ),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> showSuccess() async {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 1)).then((value) {
          if (context.mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        });

        return Center(
          child: SpFadeIn.bound(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: ColorScheme.of(context).readOnly.surface3,
              child: SpFadeIn.bound(
                duration: Durations.long1,
                child: Icon(
                  SpIcons.checkCircle,
                  size: 56,
                  color: ColorScheme.of(context).bootstrap.success.color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<T?> showLoading<T>({
    required Future<T?> Function() future,
    required String? debugSource,
  }) async {
    if (debugSource != null) AppLogger.info("LOADING... $debugSource");

    Completer<T?> completer = Completer();
    future().then((value) => completer.complete(value));

    if (!kIsWeb && Platform.isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (context) => _loadingBuilder<T>(context, completer, debugSource),
        barrierDismissible: false,
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (context) => _loadingBuilder<T>(context, completer, debugSource),
        barrierDismissible: false,
      );
    }
  }

  Widget _loadingBuilder<T>(BuildContext context, Completer<T?> future, String? debugSource) {
    return FutureBuilder<T?>(
      future: future.future.then((value) {
        if (debugSource != null) AppLogger.info("LOADED $debugSource with $value");
        if (context.mounted) {
          Navigator.of(context).pop(value);
        }
        return value;
      }),
      builder: (context, snapshot) {
        return const Center(
          child: CircularProgressIndicator.adaptive(),
        );
      },
    );
  }
}
