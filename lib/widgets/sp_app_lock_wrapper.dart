import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpAppLockWrapper extends StatelessWidget {
  const SpAppLockWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      child: child,
      builder: (context, provider, child) {
        return Stack(
          children: [
            child!,
            Visibility(
              visible: provider.hasAppLock,
              child: const _LockedBarrier(),
            ),
          ],
        );
      },
    );
  }
}

class _LockedBarrier extends StatefulWidget {
  const _LockedBarrier();

  @override
  State<_LockedBarrier> createState() => _LockedBarrierState();
}

class _LockedBarrierState extends State<_LockedBarrier> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController animationController;

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

    authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      authenticate(force: false);
    }
  }

  Future<void> authenticate({
    bool force = false,
  }) async {
    await Future.microtask(() {});

    if (!mounted) return;
    final provider = context.read<AppLockProvider>();

    // Skip authentication if already authenticated, unless forced (e.g., manual unlock button press)
    // This prevents duplicate authentication attempts when app lifecycle triggers resume
    if (provider.authenticated && !force) return;

    // Avoid duplicate authentication attempts
    if (provider.authenticating) return;
    if (animationController.value != 1) animationController.animateTo(1);
    if (showBarrier != true) {
      setState(() => showBarrier = true);
    }

    await provider.authenticateIfHas(
      context: context,
      debugSource: '$runtimeType#authenticate',
    );

    if (!mounted) return;
    if (provider.authenticated) {
      await animationController.reverse(from: 1.0);
      setState(() => showBarrier = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showBarrier) buildBlurFilter(),
        if (showBarrier) buildActionButtons(context),
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

  Widget buildActionButtons(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 48,
      child: Center(
        child: FadeTransition(
          opacity: animationController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: kIsCupertino ? 8.0 : 4.0,
            children: [
              buildUnlockButtons(),
              if (context.read<AppLockProvider>().appLock.pin != null) buildForgotPinButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildForgotPinButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.tinted(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => context.read<AppLockProvider>().forgotPin(context),
        child: Text(tr('button.forgot_pin')),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => context.read<AppLockProvider>().forgotPin(context),
        label: Text(tr('button.forgot_pin')),
      );
    }
  }

  Widget buildUnlockButtons() {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => authenticate(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8.0,
          children: [
            const Icon(SpIcons.lock),
            Text(tr('button.unlock')),
          ],
        ),
      );
    } else {
      return FilledButton.icon(
        icon: const Icon(SpIcons.lock),
        onPressed: () => authenticate(force: true),
        label: Text(tr('button.unlock')),
      );
    }
  }
}
