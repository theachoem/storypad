import 'dart:ui';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/widgets/sp_pin_unlock.dart';

class SpAppLockWrapper extends StatelessWidget {
  const SpAppLockWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  static Future<void> authenticateIfHas(BuildContext context) async {
    if (context.read<AppLockProvider>().hasAppLock) {
      await context.findAncestorStateOfType<_LockedState>()?.authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      child: child,
      builder: (context, provider, child) {
        return _Locked(child: child!);
      },
    );
  }
}

class _Locked extends StatefulWidget {
  const _Locked({
    required this.child,
  });

  final Widget child;

  @override
  State<_Locked> createState() => _LockedState();
}

class _LockedState extends State<_Locked> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController animationController;

  bool authenticated = false;
  bool showBarrier = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    animationController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: Durations.long1,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    animationController.dispose();
    super.dispose();
  }

  // when native sheet close, it also trigger [resumed] which lead to loop calling [authenticate]
  // this variable is to ensure that if closed, no need to recall [authenticate]
  bool authenticatedSheetClosed = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        authenticated = false;
        authenticatedSheetClosed = false;
        break;
      case AppLifecycleState.resumed:
        if (authenticatedSheetClosed) return;
        if (authenticated) return;
        if (animationController.value != 1) animationController.animateTo(1);
        if (showBarrier != true) setState(() => showBarrier = true);

        await authenticate();
        authenticatedSheetClosed = true;

        break;
    }
  }

  Future<void> authenticate() async {
    await Future.microtask(() {});

    final context = this.context;
    if (!context.mounted) return;

    bool authenticated;

    if (context.read<AppLockProvider>().appLock.pin != null) {
      authenticated = await SpPinUnlock.openConfirmation(
        context: context,
        title: SpPinUnlockTitle.enter_your_pin,
        invalidPinTitle: SpPinUnlockTitle.incorrect_pin,
        correctPin: context.read<AppLockProvider>().appLock.pin!,
        onConfirmWithBiometrics: context.read<AppLockProvider>().localAuth.canCheckBiometrics == true
            ? () =>
                context.read<AppLockProvider>().localAuth.authenticate(title: tr('dialog.unlock_to_open_the_app.title'))
            : null,
      );
    } else {
      authenticated = await context
          .read<AppLockProvider>()
          .localAuth
          .authenticate(title: tr('dialog.unlock_to_open_the_app.title'));
    }

    if (authenticated) {
      await animationController.reverse(from: 1.0);
      setState(() => showBarrier = false);
    }
  }

  Future<void> forgotPin() async {
    final context = this.context;
    final questions = context.read<AppLockProvider>().appLock.securityAnswers?.keys.toList() ?? [];

    final selectedQuestion = await showConfirmationDialog(
      context: context,
      title: '',
      toggleable: false,
      actions: questions.map((question) {
        return AlertDialogAction(key: question, label: question.translatedQuestion);
      }).toList(),
    );

    if (context.mounted && selectedQuestion != null) {
      final answer = context.read<AppLockProvider>().appLock.securityAnswers![selectedQuestion];
      final corrected = await showTextAnswerDialog(
        context: context,
        title: selectedQuestion.translatedQuestion,
        isCaseSensitive: false,
        keyword: answer!,
      );

      if (context.mounted && corrected == true) {
        context.read<AppLockProvider>().forceResetPIN(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (showBarrier) buildBlurFilter(),
        if (showBarrier) buildUnlockButton(context),
      ],
    );
  }

  Widget buildBlurFilter() {
    return Positioned.fill(
      child: FadeTransition(
        opacity: animationController,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: ColorScheme.of(context).surface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget buildUnlockButton(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 48,
      child: Center(
        child: FadeTransition(
          opacity: animationController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4.0,
            children: [
              FilledButton.icon(
                icon: Icon(Icons.lock_outline),
                onPressed: () => authenticate(),
                label: Text(tr('button.unlock')),
              ),
              if (context.read<AppLockProvider>().appLock.pin != null)
                OutlinedButton.icon(
                  onPressed: () => forgotPin(),
                  label: Text(tr('button.forgot_pin')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
