import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  Future<T?> showLoading<T>({
    required Future<T?> Function() future,
    required String? debugSource,
  }) async {
    if (debugSource != null) {
      debugPrint("LOADING $debugSource");
    }

    Completer<T?> completer = Completer();
    future().then((value) => completer.complete(value));

    if (!kIsWeb && Platform.isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (context) => _loadingBuilder<T>(context, completer),
        barrierDismissible: false,
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (context) => _loadingBuilder<T>(context, completer),
        barrierDismissible: false,
      );
    }
  }

  Widget _loadingBuilder<T>(BuildContext context, Completer<T?> future) {
    return FutureBuilder<T?>(
      future: future.future.then((value) {
        if (context.mounted) Navigator.of(context).pop(value);
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
